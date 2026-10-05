import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_removal_hooks.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_metier_pull_handlers.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/cours_eviction.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/per_cours_keyset_puller.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_dao.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_pull_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_purge.dart';
import 'package:school_app_flutter/features/course_programme/data/repositories/chapitre_pull_repository.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_transfer_api.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le programme de cours (Cours ▸ Mes cours) : lecture 100 % locale, écriture
/// 100 % outbox. Appelé APRÈS [registerAcademicsOffline] : le flux des
/// chapitres itère les cours que le pull cours a rangés, et le retrait d'un
/// cours réaffecté passe par la [CoursEviction] d'academics.
void registerCourseProgramme(GetIt getIt) {
  final requiredAuth = getIt<Map<String, dynamic>>();

  // ── Local ──
  getIt.registerLazySingleton<ChapitreDao>(
    () => ChapitreDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<ChapitrePullWriter>(
    () => ChapitrePullWriter(getIt<Database>()),
  );
  // Les fichiers des ressources : leur magasin et leur clé à eux.
  getIt.registerLazySingleton<EncryptedBlobStore>(
    instanceName: AppConstants.courseProgrammeDirectoryName,
    () => EncryptedBlobStore(
      directoryName: AppConstants.courseProgrammeDirectoryName,
      keyService: BlobKeyService(
        getIt<FlutterSecureStorage>(),
        storageKey: AppConstants.courseProgrammeKeyStorageKey,
      ),
    ),
  );
  getIt.registerLazySingleton<ProgrammeBlobs>(
    () => ProgrammeBlobs(
      store: getIt<EncryptedBlobStore>(
        instanceName: AppConstants.courseProgrammeDirectoryName,
      ),
      db: getIt<Database>(),
    ),
  );
  getIt.registerLazySingleton<ProgrammePurge>(
    () => ProgrammePurge(db: getIt<Database>(), blobs: getIt<ProgrammeBlobs>()),
  );

  // ── Réseau ──
  getIt.registerLazySingleton<ProgrammeSyncApi>(
    () => ProgrammeSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ProgrammeTransferApi>(
    () => ProgrammeTransferApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ChapitrePullRepository>(
    () => ChapitrePullRepository(
      api: getIt<ProgrammeSyncApi>(),
      writer: getIt<ChapitrePullWriter>(),
      puller: getIt<PerCoursKeysetPuller>(),
      requiredAuth: requiredAuth,
    ),
  );

  // ── Retraits : cours réaffecté, chapitre ou cours disparu ──
  getIt<CoursEviction>().register(
    cursorPrefix: kAcademicsChapitresResourcePrefix,
    evict: (coursId) => getIt<ProgrammePurge>().purgeCours(coursId),
  );
  for (final resource in const ['academics_chapitres', 'academics_cours']) {
    getIt<TombstoneRemovalHooks>().add(
      resource,
      (_) async => getIt<ProgrammeBlobs>().reclaimOrphans(),
    );
  }

  // ── Descente (après le pull cours, qui range les cours itérés) ──
  getIt<PullCoordinator>().registerHandler(
    CoursScopedPullHandler(
      resource: kAcademicsChapitresResourcePrefix,
      requiredPermissions: const [Perm.academicsCourseRead],
      pull: getIt<ChapitrePullRepository>().syncChapitres,
    ),
  );
}
