import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_blob_store.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_key_service.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_maintenance_dao.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';

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
  getIt.registerLazySingleton<EditiqueBlobStore>(
    () => EditiqueBlobStore(
      keyService: getIt<EditiqueCacheKeyService>(),
      onKeyRotated: () => getIt<EditiqueCacheMaintenanceDao>().purgeAll(),
    ),
  );

  // ── Le cache composé : le seul point d'entrée légitime des deux ──
  getIt.registerLazySingleton<EditiqueDocumentCache>(
    () => EditiqueDocumentCache(
      index: getIt<EditiqueCacheDao>(),
      maintenance: getIt<EditiqueCacheMaintenanceDao>(),
      store: getIt<EditiqueBlobStore>(),
      ids: getIt<IdGenerator>(),
    ),
  );
}
