import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/camera/platform_camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/student_photo/data/photo/image_square_photo_encoder.dart';
import 'package:school_app_flutter/features/student_photo/data/roster/classes_roster_source.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/class_roster_source.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/square_photo_encoder.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_draft_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/edit/student_photo_edit_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_network_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_scope.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_blobs.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_sync_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_write_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/repositories/student_photo_repository_impl.dart';
import 'package:school_app_flutter/features/student_photo/data/student_photo_change_bus.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_api.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_fetcher.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_outbox_handler.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_pull_handler.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_puller.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/load_photo_session_classes_use_case.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/registry/student_photo_registry.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_removal_hooks.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// La photo de l'élève : sa table, son magasin chiffré, son flux, son envoi.
///
/// Enregistré après l'inscription : le coordinateur tire dans l'ordre
/// d'enregistrement, et une photo n'a de sens qu'une fois l'élève descendu.
void registerStudentPhoto(GetIt getIt) {
  getIt.registerLazySingleton<StudentPhotoChangeBus>(StudentPhotoChangeBus.new);
  getIt.registerLazySingleton<StudentPhotoDao>(
    () => StudentPhotoDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StudentPhotoWriteDao>(
    () => StudentPhotoWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StudentPhotoSyncDao>(
    () => StudentPhotoSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StudentPhotoApi>(
    () => StudentPhotoApi(getIt<Dio>()),
  );
  // Un magasin et une clé à elles. Une clé renouvelée efface tous les
  // fichiers : les marques de copie partent avec eux, et l'affichage le sait.
  getIt.registerLazySingleton<StudentPhotoBlobs>(
    () => StudentPhotoBlobs(
      EncryptedBlobStore(
        directoryName: AppConstants.studentPhotosDirectoryName,
        keyService: BlobKeyService(
          getIt<FlutterSecureStorage>(),
          storageKey: AppConstants.studentPhotosKeyStorageKey,
        ),
        onKeyRotated: () async {
          await getIt<StudentPhotoDao>().forgetAllCaches();
          getIt<StudentPhotoChangeBus>().emitAll();
        },
      ),
    ),
  );
  // La tombe d'un élève emporte sa ligne photo (table fille) : ses copies
  // d'affichage, elles, dorment sur disque et l'avatar les montrerait encore.
  // Les octets d'un geste en attente partent à l'envoi (ligne absente).
  getIt<TombstoneRemovalHooks>().add('students', (studentId) async {
    await getIt<StudentPhotoBlobs>().deleteCaches(studentId);
    getIt<StudentPhotoChangeBus>().emit({studentId});
  });
  getIt.registerLazySingleton<StudentPhotoFetcher>(
    () => StudentPhotoFetcher(
      api: getIt<StudentPhotoApi>(),
      photos: getIt<StudentPhotoDao>(),
      blobs: getIt<StudentPhotoBlobs>(),
      tenant: getIt<TenantScope>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
  getIt.registerLazySingleton<StudentPhotoRepository>(
    () => StudentPhotoRepositoryImpl(
      photos: getIt<StudentPhotoDao>(),
      writer: getIt<StudentPhotoWriteDao>(),
      blobs: getIt<StudentPhotoBlobs>(),
      fetcher: getIt<StudentPhotoFetcher>(),
      bus: getIt<StudentPhotoChangeBus>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<LoadStudentPhotoIndexUseCase>(
    () => LoadStudentPhotoIndexUseCase(getIt<StudentPhotoRepository>()),
  );
  getIt.registerFactory<ReadStudentPhotoUseCase>(
    () => ReadStudentPhotoUseCase(getIt<StudentPhotoRepository>()),
  );
  getIt.registerFactory<SaveStudentPhotoUseCase>(
    () => SaveStudentPhotoUseCase(getIt<StudentPhotoRepository>()),
  );
  getIt.registerFactory<RemoveStudentPhotoUseCase>(
    () => RemoveStudentPhotoUseCase(getIt<StudentPhotoRepository>()),
  );
  // La source des avatars : un service de longue vie, posé à la racine par
  // `PersonPhotoScope`. Ce n'est pas un BLoC — il sert tous les écrans.
  getIt.registerLazySingleton<StudentPhotoRegistry>(
    () => StudentPhotoRegistry(
      loadIndex: getIt<LoadStudentPhotoIndexUseCase>(),
      read: getIt<ReadStudentPhotoUseCase>(),
    ),
  );

  // ── Prise de vue (modale, séance) ───────────────────────────────────────
  getIt.registerLazySingleton<CameraViewfinderGateway>(
    PlatformCameraViewfinderGateway.new,
  );
  getIt.registerLazySingleton<SquarePhotoEncoder>(
    () => const ImageSquarePhotoEncoder(),
  );
  getIt.registerLazySingleton<ClassRosterSource>(
    () => ClassesRosterSource(
      classrooms: getIt<GetOfflineClassroomsUseCase>(),
      roster: getIt<GetOfflineRosterUseCase>(),
    ),
  );
  getIt.registerFactory<LoadPhotoSessionClassesUseCase>(
    () => LoadPhotoSessionClassesUseCase(
      rosters: getIt<ClassRosterSource>(),
      photos: getIt<StudentPhotoRepository>(),
    ),
  );
  getIt.registerFactory<StudentPhotoCaptureCubit>(
    () => StudentPhotoCaptureCubit(
      cameras: getIt<CameraViewfinderGateway>(),
      files: getIt<DocumentCaptureGateway>(),
      encoder: getIt<SquarePhotoEncoder>(),
      save: getIt<SaveStudentPhotoUseCase>(),
    ),
  );
  getIt.registerFactory<StudentPhotoEditCubit>(
    () => StudentPhotoEditCubit(remove: getIt<RemoveStudentPhotoUseCase>()),
  );
  getIt.registerFactory<StudentPhotoDraftCubit>(
    () => StudentPhotoDraftCubit(save: getIt<SaveStudentPhotoUseCase>()),
  );
  getIt.registerFactory<PhotoSessionCubit>(
    () => PhotoSessionCubit(
      classes: getIt<LoadPhotoSessionClassesUseCase>(),
      save: getIt<SaveStudentPhotoUseCase>(),
      encoder: getIt<SquarePhotoEncoder>(),
      cameras: getIt<CameraViewfinderGateway>(),
      files: getIt<DocumentCaptureGateway>(),
    ),
  );
  getIt.registerFactory<PhotoNetworkCubit>(
    () => PhotoNetworkCubit(getIt<ConnectivityService>()),
  );

  getIt<PullCoordinator>().registerHandler(
    StudentPhotoPullHandler(
      StudentPhotoPuller(
        api: getIt<StudentPhotoApi>(),
        runner: KeysetPullRunner(getIt<SyncMetaDao>()),
        photos: getIt<StudentPhotoDao>(),
        blobs: getIt<StudentPhotoBlobs>(),
        fetcher: getIt<StudentPhotoFetcher>(),
        bus: getIt<StudentPhotoChangeBus>(),
        currentUser: getIt<CurrentUserContext>(),
        requiredAuth: getIt<Map<String, dynamic>>(),
      ),
    ),
  );
  // Une photo attend l'accusé de l'inscription de son élève (`blocked`).
  getIt<SyncEngine>().registerHandler(
    StudentPhotoOutboxHandler(
      api: getIt<StudentPhotoApi>(),
      sync: getIt<StudentPhotoSyncDao>(),
      photos: getIt<StudentPhotoDao>(),
      blobs: getIt<StudentPhotoBlobs>(),
      bus: getIt<StudentPhotoChangeBus>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
}
