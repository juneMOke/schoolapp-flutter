import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/documents/data/datasources/offline/editique_document_pull_api.dart';
import 'package:school_app_flutter/features/documents/data/datasources/offline/editique_document_pull_handler.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_store.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_session_guard.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_entitlement.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_key_service.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_maintenance_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/find_cached_document_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/list_cached_documents_use_case.dart';

/// Registrar de la branche offline **Éditique** — le cache de restitution des
/// pièces scellées (ADR-012 D-2/D-7, AM-10). Appelé depuis
/// `registerOfflineModules` après le socle et les autres branches.
///
/// Ordre : clé → magasin d'octets → DAO d'index → cache composé. Aucun BLoC, et
/// **aucun consommateur** à ce stade : la restitution hors ligne dans l'écran
/// est le lot L3.5, le remplissage par la synchro le lot L3.4. Ce qui est câblé
/// ici est ce qui doit exister avant eux.
///
/// ## Tout est paresseux, et ce n'est pas un détail
///
/// La DI offline est montée **avant l'authentification** : au moment de cet
/// appel, ni le rôle ni l'école ne sont connus. Rien ici ne doit donc toucher
/// la plateforme — pas de répertoire créé, pas de clé AES générée, pas de
/// secure storage lu. Tout attend la première pièce réellement mise en cache,
/// ce qui laissera au lot L3.6 la possibilité d'interposer sa garde de rôle
/// (RG-012-4) sans que la tablette d'un enseignant se soit déjà vu fabriquer
/// une clé de cache.
void registerDocumentsOffline(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();

  // ── Clé du magasin ──
  // Distincte de celle de SQLCipher : la détruire rend les pièces illisibles
  // sans rien toucher de la base, ce qui est la primitive d'effacement de D-7.
  getIt.registerLazySingleton<EditiqueCacheKeyService>(
    () => EditiqueCacheKeyService(getIt<FlutterSecureStorage>()),
  );

  // ── Index (lecture/mesure d'un côté, retrait de l'autre) ──
  getIt.registerLazySingleton<EditiqueCacheDao>(
    () => EditiqueCacheDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EditiqueCacheMaintenanceDao>(
    () => EditiqueCacheMaintenanceDao(getIt<Database>()),
  );

  // ── Magasin d'octets (fichiers chiffrés hors base) ──
  // `onKeyRotated` ferme la seule fenêtre où l'index survivrait à ses octets :
  // une clé retrouvée neuve (réinstallation, restauration de sauvegarde
  // Android, keystore effacé) rend tout fichier illisible, donc le magasin les
  // efface — et l'index doit les oublier au même instant, sinon il continue
  // d'annoncer au budget des pièces qui n'existent plus. La résolution est
  // paresseuse : rien n'est touché tant que le magasin lui-même dort.
  //
  // Et le curseur avec, pour la même raison qu'à l'ouverture de session : vider
  // l'index sans rembobiner le delta laisserait un curseur en avance sur une
  // base vide, et le catalogue ne se repeuplerait plus jamais de ce qui a été
  // scellé avant.
  getIt.registerLazySingleton<EditiqueBlobStore>(
    () => EditiqueBlobStore(
      keyService: getIt<EditiqueCacheKeyService>(),
      onKeyRotated: () async {
        await getIt<EditiqueCacheMaintenanceDao>().purgeAll();
        await getIt<SyncMetaDao>().deleteCursorsOf(kEditiqueDocumentsResource);
      },
    ),
  );

  // ── Ce que la tablette peut ressortir hors ligne ──
  // Lit l'index seul : la question « qu'ai-je déjà ? » ne doit jamais ouvrir un
  // fichier ni résoudre une clé.
  getIt.registerFactory<FindCachedDocumentUseCase>(
    () => FindCachedDocumentUseCase(
      getIt<EditiqueCacheDao>(),
      getIt<CurrentUserContext>(),
      getIt<EditiqueCacheAccess>(),
    ),
  );

  getIt.registerFactory<ListCachedDocumentsUseCase>(
    () => ListCachedDocumentsUseCase(
      getIt<EditiqueCacheDao>(),
      getIt<CurrentUserContext>(),
      getIt<EditiqueCacheAccess>(),
    ),
  );

  // ── Garde de profil (RG-012-4) ──
  // Fail-closed par construction : `auth_local_user` n'est écrit que par un
  // login online réussi, donc son absence se lit « pas de droit ». Le secure
  // storage, lui, rend une chaîne vide au démarrage à froid — une valeur qu'une
  // garde écrite en négatif aurait prise pour une autorisation.
  getIt.registerLazySingleton<EditiqueCacheAccess>(
    () => LocalEditiqueCacheAccess(getIt<AuthLocalDao>()),
  );

  // ── Le cache composé : le seul point d'entrée légitime des deux ──
  getIt.registerLazySingleton<EditiqueDocumentCache>(
    () => EditiqueDocumentCache(
      index: getIt<EditiqueCacheDao>(),
      maintenance: getIt<EditiqueCacheMaintenanceDao>(),
      store: getIt<EditiqueBlobStore>(),
      ids: getIt<IdGenerator>(),
      access: getIt<EditiqueCacheAccess>(),
    ),
  );

  // ── Ce qu'une ouverture de session décide du cache (D-7, RG-012-21) ──
  getIt.registerLazySingleton<EditiqueCacheSessionGuard>(
    () => EditiqueCacheSessionGuard(
      cache: getIt<EditiqueDocumentCache>(),
      authLocalDao: getIt<AuthLocalDao>(),
      syncMetaDao: getIt<SyncMetaDao>(),
    ),
  );

  // ── Handlers de pull delta ──
  // Le catalogue des pièces scellées : ce qui existe ailleurs. Les octets
  // continuent d'être tirés un par un — jamais dans une page de delta.
  getIt.registerLazySingleton<EditiqueDocumentPullApi>(
    () => EditiqueDocumentPullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EditiqueDocumentPullRepositoryImpl>(
    () => EditiqueDocumentPullRepositoryImpl(
      api: getIt<EditiqueDocumentPullApi>(),
      cache: getIt<EditiqueDocumentCache>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      currentUser: getIt<CurrentUserContext>(),
      requiredAuth: requiredAuth,
      // La MÊME autorité que celle qui garde l'écriture de l'index. Sans elle,
      // le cycle descendait le catalogue entier, n'en gardait rien, et avançait
      // quand même le curseur — ces pièces n'étaient jamais redemandées.
      access: getIt<EditiqueCacheAccess>(),
    ),
  );
  getIt<PullCoordinator>().registerHandler(
    EditiqueDocumentPullHandler(getIt<EditiqueDocumentPullRepositoryImpl>()),
  );
}
