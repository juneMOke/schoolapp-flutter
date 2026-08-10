import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/components/status/outbox_errors_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/di/offline_modules/enrollment_finance_offline_di.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/session_reauthenticator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/core/di/offline_modules/classroom_attendance_offline_di.dart';
import 'package:school_app_flutter/core/di/offline_modules/academics_offline_di.dart';
import 'package:school_app_flutter/core/di/offline_modules/documents_offline_di.dart';
import 'package:uuid/uuid.dart';

/// Enregistre le socle offline dans le conteneur GetIt.
///
/// À appeler depuis `configureDependencies()` APRÈS `FlutterSecureStorage`
/// (nécessaire pour la clé SQLCipher) et AVANT les features (qui consomment la
/// base, l'outbox et le moteur de synchro).
///
/// Ouvre la base chiffrée de façon eager (await) car la clé et le schéma
/// doivent être prêts avant toute lecture/écriture métier.
///
/// [database] : base pré-ouverte injectée (tests). Fournie, on saute la
/// génération de clé et l'ouverture SQLCipher (canal plateforme indisponible
/// hors device) et on l'enregistre telle quelle — les tests passent une base
/// sqflite en mémoire (ffi) construite depuis `buildOfflineSchema()`.
Future<void> registerOfflineCore(GetIt getIt, {Database? database}) async {
  getIt.registerLazySingleton<Uuid>(() => const Uuid());

  getIt.registerLazySingleton<IdGenerator>(() => IdGenerator(getIt<Uuid>()));

  getIt.registerLazySingleton<DatabaseKeyService>(
    () => DatabaseKeyService(getIt<FlutterSecureStorage>(), getIt<Uuid>()),
  );

  // Identifiant d'installation (ADR-012 zone Z3) — même patron que la clé
  // SQLCipher : généré une fois, persisté en secure storage, jamais relevé
  // depuis la plateforme.
  getIt.registerLazySingleton<DeviceIdentityService>(
    () => DeviceIdentityService(getIt<FlutterSecureStorage>(), getIt<Uuid>()),
  );

  final Database resolvedDatabase;
  if (database != null) {
    resolvedDatabase = database;
  } else {
    final dbKey = await getIt<DatabaseKeyService>().getOrCreateKey();
    resolvedDatabase = await openOfflineDatabase(
      dbKey: dbKey,
      schema: buildOfflineSchema(),
    );
  }
  getIt.registerLazySingleton<Database>(() => resolvedDatabase);

  getIt.registerLazySingleton<OutboxDao>(() => OutboxDao(getIt<Database>()));
  getIt.registerLazySingleton<SyncMetaDao>(
    () => SyncMetaDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<AuthLocalDao>(
    () => AuthLocalDao(getIt<Database>()),
  );

  // Uid courant (ADR-010 D-05) : alimenté par l'auth, lu au write-time par les
  // chemins offline pour estampiller `authorId` sur les payloads `/sync`.
  getIt.registerLazySingleton<CurrentUserContext>(() => CurrentUserContext());

  // Ensemble effectif des permissions (ADR-014 §4) : alimenté par l'auth, lu
  // par la boucle de pull pour sauter les ressources que ce compte n'a pas le
  // droit de lire — sans quoi chaque cycle collectionnerait des 403.
  getIt.registerLazySingleton<CurrentPermissions>(() => CurrentPermissions());

  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(getIt<Connectivity>()),
  );

  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      outbox: getIt<OutboxDao>(),
      connectivity: getIt<ConnectivityService>(),
      // Gate crédentiels AU MOTEUR (V1.1, revue adversariale) : les repos
      // offline flushent en direct (hors cubit) — le goulot doit être ici.
      // Lazy : AuthSessionManager est enregistré plus tard dans
      // `configureDependencies()`, résolu au premier flush.
      credentialsProbe: getIt<AuthSessionManager>(),
      // Garde d'attribution (tablette partagée) : ne jamais pousser sous le
      // jeton du porteur courant l'écriture hors ligne d'un autre compte.
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  // Orchestrateur de pull delta (SOC-1) — pendant *lecture* du SyncEngine. Les
  // branches enregistrent leurs `PullHandler` dessus dans
  // `registerOfflineModules()` ; déclenché au retour online par le cubit ci-dessous.
  // Bus de fin de pull : réveille les écrans qui ont déjà lu un cache froid
  // (l'hydratation réseau répond bien après la lecture locale). Enregistré
  // AVANT le coordinateur, qui le consomme.
  getIt.registerLazySingleton<PullCompletionBus>(() => PullCompletionBus());

  getIt.registerLazySingleton<PullCoordinator>(
    () => PullCoordinator(
      connectivity: getIt<ConnectivityService>(),
      completionBus: getIt<PullCompletionBus>(),
      permissions: getIt<CurrentPermissions>(),
    ),
  );

  // Cubit global d'état de synchro : source de la pastille du top bar. En
  // factory (règle #2), fourni UNE fois à la racine (`main.dart`, `.value`), ce
  // qui garantit une instance unique app-lifetime accessible via `context`.
  getIt.registerFactory<SyncStatusCubit>(
    () => SyncStatusCubit(
      outbox: getIt<OutboxDao>(),
      connectivity: getIt<ConnectivityService>(),
      syncEngine: getIt<SyncEngine>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      pullCoordinator: getIt<PullCoordinator>(),
      // Guardian de révocation (ADR-010 D-11) : évalué APRÈS le flush.
      revocationEvaluator: getIt<AuthSessionManager>(),
      // Sonde de crédentiels (V1.1) : sans jetons utilisables, la boucle ne
      // flushe pas (zéro 401/attempt) et surface « Reconnexion requise ».
      credentialsProbe: getIt<AuthSessionManager>(),
      // Ré-authentification silencieuse : une session ouverte offline revient
      // avec un access vide ou périmé — on mint AVANT de flusher/puller plutôt
      // que de laisser la première écriture métier découvrir le jeton mort.
      // Lazy comme ci-dessus : enregistré plus loin dans `configureDependencies`.
      reauthenticator: getIt<SessionReauthenticator>(),
    ),
  );

  // Feuille de reprise des écritures terminales (`SYNC_ERROR`). En factory
  // (règle #2) : une instance par ouverture de la feuille, fermée avec elle.
  getIt.registerFactory<OutboxErrorsCubit>(
    () => OutboxErrorsCubit(
      outbox: getIt<OutboxDao>(),
      syncEngine: getIt<SyncEngine>(),
      // Explication de l'attente d'un autre compte (tablette partagée) :
      // nombre, ancienneté et nom, jamais le contenu.
      currentUser: getIt<CurrentUserContext>(),
      authorDirectory: getIt<AuthSessionManager>(),
    ),
  );
}

/// Point d'extension des branches offline.
///
/// Chaque branche enregistre ici ses DataSources locales, repositories
/// offline-first, handlers d'outbox (`getIt<SyncEngine>().registerHandler(...)`)
/// et BLoCs, en appelant son registrar dédié. C'est le SEUL corps du socle que
/// les branches éditent pour la DI — conflit de merge réduit à ces lignes.
///
/// Appelé en fin de `configureDependencies()` (après les features online, dont
/// les DataSources distantes réutilisées par les handlers).
void registerOfflineModules(GetIt getIt) {
  registerEnrollmentFinanceOffline(getIt); // branche A
  registerClassroomAttendanceOffline(getIt); // branche B
  registerAcademicsOffline(getIt); // Notes / Cours (academics + schedule)
  registerDocumentsOffline(getIt); // Éditique — cache de restitution (ADR-012)
}
