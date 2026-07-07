import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/database_key_service.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/di/offline_modules/classroom_attendance_offline_di.dart';
import 'package:uuid/uuid.dart';

/// Enregistre le socle offline dans le conteneur GetIt.
///
/// À appeler depuis `configureDependencies()` APRÈS `FlutterSecureStorage`
/// (nécessaire pour la clé SQLCipher) et AVANT les features (qui consomment la
/// base, l'outbox et le moteur de synchro).
///
/// Ouvre la base chiffrée de façon eager (await) car la clé et le schéma
/// doivent être prêts avant toute lecture/écriture métier.
Future<void> registerOfflineCore(GetIt getIt) async {
  getIt.registerLazySingleton<Uuid>(() => const Uuid());

  getIt.registerLazySingleton<IdGenerator>(() => IdGenerator(getIt<Uuid>()));

  getIt.registerLazySingleton<DatabaseKeyService>(
    () => DatabaseKeyService(getIt<FlutterSecureStorage>(), getIt<Uuid>()),
  );

  final dbKey = await getIt<DatabaseKeyService>().getOrCreateKey();
  final database = await openOfflineDatabase(
    dbKey: dbKey,
    schema: buildOfflineSchema(),
  );
  getIt.registerLazySingleton<Database>(() => database);

  getIt.registerLazySingleton<OutboxDao>(() => OutboxDao(getIt<Database>()));
  getIt.registerLazySingleton<SyncMetaDao>(
    () => SyncMetaDao(getIt<Database>()),
  );

  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(getIt<Connectivity>()),
  );

  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      outbox: getIt<OutboxDao>(),
      connectivity: getIt<ConnectivityService>(),
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
  // registerEnrollmentFinanceOffline(getIt);     // branche A
  registerClassroomAttendanceOffline(getIt); // branche B
}
