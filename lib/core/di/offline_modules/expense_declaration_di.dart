import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/money/cash_closure_reader.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_declaration_cancellation.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/platform_blob_files.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_declaration_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_declaration_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_api.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_declaration_outbox_handler.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_declaration_repository.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/declare_expense_use_case.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_voucher_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_api.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_blobs.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_voucher_repository.dart';

/// La dépense **déclarée** (v3) : la photo du bon — son magasin chiffré à
/// lui, avec sa clé, enregistré sous le nom de son répertoire comme les
/// pièces du personnel —, l'écriture de la déclaration et son envoi.
///
/// Appelé par `registerExpenseOffline`, **après** les DAO du module et le
/// `SyncEngine`.
void registerExpenseDeclaration(GetIt getIt) {
  getIt.registerLazySingleton<EncryptedBlobStore>(
    instanceName: AppConstants.expenseVouchersDirectoryName,
    () => EncryptedBlobStore(
      directoryName: AppConstants.expenseVouchersDirectoryName,
      files: platformBlobFiles(AppConstants.expenseVouchersDirectoryName),
      keyService: BlobKeyService(
        getIt<FlutterSecureStorage>(),
        storageKey: AppConstants.expenseVouchersKeyStorageKey,
      ),
    ),
  );
  getIt.registerLazySingleton<ExpenseVoucherBlobs>(
    () => ExpenseVoucherBlobs(
      getIt<EncryptedBlobStore>(
        instanceName: AppConstants.expenseVouchersDirectoryName,
      ),
    ),
  );
  getIt.registerLazySingleton<ExpenseVoucherApi>(
    () => ExpenseVoucherApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ExpenseVoucherRepository>(
    () => ExpenseVoucherRepositoryImpl(
      blobs: getIt<ExpenseVoucherBlobs>(),
      api: getIt<ExpenseVoucherApi>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );

  getIt.registerLazySingleton<ExpenseDeclarationDao>(
    () => ExpenseDeclarationDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<ExpenseDeclarationApi>(
    () => ExpenseDeclarationApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<ExpenseDeclarationRepository>(
    () => ExpenseDeclarationRepositoryImpl(
      dao: getIt<ExpenseDeclarationDao>(),
      types: getIt<ExpenseTypeDao>(),
      blobs: getIt<ExpenseVoucherBlobs>(),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  // Résolu à l'appel, pas à l'enregistrement : la Trésorerie, qui tient les
  // clôtures, s'enregistre après ce module.
  getIt.registerFactory<ExpenseDeclarationCancellation>(
    () => ExpenseDeclarationCancellation(
      getIt.isRegistered<CashClosureReader>()
          ? getIt<CashClosureReader>()
          : null,
    ),
  );
  getIt.registerFactory<DeclareExpenseUseCase>(
    () => DeclareExpenseUseCase(getIt<ExpenseDeclarationRepository>()),
  );
  getIt<SyncEngine>().registerHandler(
    ExpenseDeclarationOutboxHandler(
      api: getIt<ExpenseDeclarationApi>(),
      dao: getIt<ExpenseDeclarationDao>(),
      blobs: getIt<ExpenseVoucherBlobs>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
}
