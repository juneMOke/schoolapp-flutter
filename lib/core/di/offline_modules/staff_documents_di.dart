import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/platform_blob_files.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_session_guard.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_document_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_transfer_api.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_document_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_document_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_dossier_cubit.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les pièces du dossier du personnel : leurs écritures, leur magasin chiffré,
/// leur envoi multipart et leur écran. Appelé par [registerStaffOffline], qui
/// a déjà posé les DAO de lecture et la fiche dont les pièces dépendent.
void registerStaffDocuments(GetIt getIt) {
  getIt.registerLazySingleton<StaffDocumentWriteDao>(
    () => StaffDocumentWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffDocumentSyncDao>(
    () => StaffDocumentSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffDocumentTransferApi>(
    () => StaffDocumentTransferApi(getIt<Dio>()),
  );
  // Les octets des pièces : leur magasin et leur clé à eux, enregistrés sous
  // le nom de leur répertoire comme celui de l'éditique.
  getIt.registerLazySingleton<EncryptedBlobStore>(
    instanceName: AppConstants.staffDocumentsDirectoryName,
    () => EncryptedBlobStore(
      directoryName: AppConstants.staffDocumentsDirectoryName,
      files: platformBlobFiles(AppConstants.staffDocumentsDirectoryName),
      keyService: BlobKeyService(
        getIt<FlutterSecureStorage>(),
        storageKey: AppConstants.staffDocumentsKeyStorageKey,
      ),
    ),
  );
  getIt.registerLazySingleton<StaffDocumentSessionGuard>(
    () => StaffDocumentSessionGuard(
      store: _staffDocumentStore(getIt),
      documents: getIt<StaffDocumentSyncDao>(),
      authLocalDao: getIt<AuthLocalDao>(),
    ),
  );

  getIt.registerLazySingleton<StaffDocumentRepository>(
    () => StaffDocumentRepositoryImpl(
      documents: getIt<StaffDocumentDao>(),
      types: getIt<StaffDocumentTypeDao>(),
      writer: getIt<StaffDocumentWriteDao>(),
      sync: getIt<StaffDocumentSyncDao>(),
      api: getIt<StaffDocumentTransferApi>(),
      store: _staffDocumentStore(getIt),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      extras: getIt<Map<String, dynamic>>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<LoadStaffDossierUseCase>(
    () => LoadStaffDossierUseCase(getIt<StaffDocumentRepository>()),
  );
  getIt.registerFactory<AddStaffDocumentUseCase>(
    () => AddStaffDocumentUseCase(getIt<StaffDocumentRepository>()),
  );
  getIt.registerFactory<OpenStaffDocumentUseCase>(
    () => OpenStaffDocumentUseCase(getIt<StaffDocumentRepository>()),
  );

  getIt.registerFactory<StaffDossierCubit>(
    () => StaffDossierCubit(
      load: getIt<LoadStaffDossierUseCase>(),
      add: getIt<AddStaffDocumentUseCase>(),
      open: getIt<OpenStaffDocumentUseCase>(),
    ),
  );

  // Une pièce attend l'accusé de sa fiche (`blocked`), comme un contrat.
  getIt<SyncEngine>().registerHandler(
    StaffDocumentOutboxHandler(
      api: getIt<StaffDocumentTransferApi>(),
      dao: getIt<StaffDocumentSyncDao>(),
      members: getIt<StaffMemberDao>(),
      store: _staffDocumentStore(getIt),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
}

EncryptedBlobStore _staffDocumentStore(GetIt getIt) =>
    getIt<EncryptedBlobStore>(
      instanceName: AppConstants.staffDocumentsDirectoryName,
    );
