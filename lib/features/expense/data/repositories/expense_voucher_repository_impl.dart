import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_directory.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_api.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_blobs.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher_image.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_voucher_repository.dart';

class ExpenseVoucherRepositoryImpl implements ExpenseVoucherRepository {
  final ExpenseVoucherBlobs _blobs;
  final ExpenseVoucherApi _api;
  final Map<String, dynamic> _extras;

  const ExpenseVoucherRepositoryImpl({
    required ExpenseVoucherBlobs blobs,
    required ExpenseVoucherApi api,
    required Map<String, dynamic> extras,
  }) : _blobs = blobs,
       _api = api,
       _extras = extras;

  @override
  Future<Either<Failure, ExpenseVoucherImage?>> voucherOf(
    Expense expense,
  ) async {
    if (!expense.isDeclaration) return const Right(null);
    // Un identifiant qui ne ferait pas un nom de fichier sûr ne touche ni au
    // magasin ni à la route.
    if (!BlobDirectory.isSafeId(ExpenseVoucherBlobs.idOf(expense.id))) {
      return const Left(NotFoundFailure('Dépense inconnue'));
    }
    try {
      final local = await _blobs.read(expense.id);
      if (local case BlobFound(:final blob)) {
        return Right(
          ExpenseVoucherImage(
            bytes: blob.bytes,
            contentType: expense.voucher?.contentType ?? 'image/jpeg',
          ),
        );
      }
      return await _download(expense);
    } catch (e) {
      return Left(StorageFailure('Lecture de la photo du bon : $e'));
    }
  }

  Future<Either<Failure, ExpenseVoucherImage?>> _download(
    Expense expense,
  ) async {
    try {
      final download = await _api.download(_extras, expense.id);
      if (download.bytes.isEmpty) return const Right(null);
      // Une copie qui ne s'écrit pas n'empêche pas de montrer la photo :
      // seul « Viser » attendra une prochaine ouverture.
      await _blobs.write(expense.id, download.bytes);
      return Right(
        ExpenseVoucherImage(
          bytes: download.bytes,
          contentType: download.contentType.isNotEmpty
              ? download.contentType
              : expense.voucher?.contentType ?? 'image/jpeg',
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Right(null);
      return Left(_failureOf(e));
    }
  }

  @override
  Future<bool> isOnDevice(String expenseId) async {
    if (!BlobDirectory.isSafeId(ExpenseVoucherBlobs.idOf(expenseId))) {
      return false;
    }
    try {
      return await _blobs.isOnDevice(expenseId);
    } catch (_) {
      return false;
    }
  }

  static Failure _failureOf(DioException e) => switch (e.response?.statusCode) {
    null => const NetworkFailure(),
    401 => const AuthFailure('Session expirée'),
    403 => const UnauthorizedFailure(),
    _ => const ServerFailure(),
  };
}
