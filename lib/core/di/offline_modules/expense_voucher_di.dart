import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/platform_blob_files.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_voucher_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_api.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_blobs.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_voucher_repository.dart';

/// La photo du bon des dépenses déclarées (v3) : son magasin chiffré à lui,
/// avec sa clé, enregistré sous le nom de son répertoire comme les pièces du
/// personnel.
void registerExpenseVoucher(GetIt getIt) {
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
}
