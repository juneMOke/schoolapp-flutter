import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_cipher.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/expense/data/repositories/expense_voucher_repository_impl.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_api.dart';
import 'package:school_app_flutter/features/expense/data/voucher/expense_voucher_blobs.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_voucher.dart';

class _MockApi extends Mock implements ExpenseVoucherApi {}

class _FakeKeyService implements BlobKeyService {
  @override
  String get storageKey => 'test';

  @override
  Future<BlobKey> getOrCreate() async => BlobKey(
    bytes: Uint8List.fromList(List<int>.generate(32, (i) => i)),
    createdNow: false,
  );

  @override
  Future<void> destroy() async {}
}

DioException _http(int? status) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: status,
        ),
);

/// DEP-17 — la photo du bon : sur le poste d'abord, sinon du serveur, puis
/// gardée chiffrée ; et c'est sa présence qui ouvre « Viser » (F40).
void main() {
  late Directory base;
  late ExpenseVoucherBlobs blobs;
  late _MockApi api;
  late ExpenseVoucherRepositoryImpl repository;

  const expenseId = '7d0c5a8e-1b2f-4c3d-9e8f-0a1b2c3d4e5f';
  final photo = Uint8List.fromList(List<int>.generate(64, (i) => i));

  Expense expense({ExpenseMode mode = ExpenseMode.declaration}) => Expense(
    id: expenseId,
    typeId: 't-1',
    title: 'Carburant',
    amountInCents: 4500,
    currency: 'USD',
    status: ExpenseStatus.paid,
    expenseDate: DateTime(2026, 11, 25),
    clientUpdatedAt: DateTime.utc(2026, 11, 25),
    mode: mode,
    voucher: const ExpenseVoucher(
      id: expenseId,
      contentType: 'image/png',
      sizeBytes: 64,
    ),
  );

  setUp(() async {
    base = await Directory.systemTemp.createTemp('expense_voucher_test');
    blobs = ExpenseVoucherBlobs(
      EncryptedBlobStore(
        directoryName: 'expense_vouchers',
        keyService: _FakeKeyService(),
        cipher: runBlobCipherTask,
        baseDirectory: () async => base,
      ),
    );
    api = _MockApi();
    repository = ExpenseVoucherRepositoryImpl(
      blobs: blobs,
      api: api,
      extras: const {},
    );
  });

  tearDown(() => base.delete(recursive: true));

  test('une demande d’autorisation n’a pas de photo, sans appel', () async {
    final result = await repository.voucherOf(
      expense(mode: ExpenseMode.authorization),
    );

    expect(result.getOrElse(() => throw 'Left'), isNull);
    verifyZeroInteractions(api);
  });

  test('la photo déjà sur le poste ne se retélécharge pas', () async {
    await blobs.write(expenseId, photo);

    final result = await repository.voucherOf(expense());

    final image = result.getOrElse(() => throw 'Left')!;
    expect(image.bytes, photo);
    expect(image.contentType, 'image/png');
    verifyZeroInteractions(api);
  });

  test('absente : téléchargée, gardée, et « Viser » s’ouvre', () async {
    when(() => api.download(any(), expenseId)).thenAnswer(
      (_) async =>
          ExpenseVoucherDownload(bytes: photo, contentType: 'image/jpeg'),
    );
    expect(await repository.isOnDevice(expenseId), isFalse);

    final result = await repository.voucherOf(expense());

    expect(result.getOrElse(() => throw 'Left')!.contentType, 'image/jpeg');
    expect(await repository.isOnDevice(expenseId), isTrue);
  });

  test('404 : pas de photo, pas d’erreur', () async {
    when(() => api.download(any(), expenseId)).thenThrow(_http(404));

    final result = await repository.voucherOf(expense());

    expect(result.getOrElse(() => throw 'Left'), isNull);
  });

  test('les quatre pannes gardent leur type (règle n°10)', () async {
    Future<Failure> failureFor(int? status) async {
      when(() => api.download(any(), expenseId)).thenThrow(_http(status));
      return (await repository.voucherOf(
        expense(),
      )).fold((f) => f, (_) => throw 'Right');
    }

    expect(await failureFor(null), isA<NetworkFailure>());
    expect(await failureFor(401), isA<AuthFailure>());
    expect(await failureFor(403), isA<UnauthorizedFailure>());
    expect(await failureFor(500), isA<ServerFailure>());
  });

  test('la politique du bon réduit plus fort, les autres ne bougent pas', () {
    expect(DocumentCapturePolicy.expenseVoucher.imageMaxDimension, 1600);
    expect(DocumentCapturePolicy.expenseVoucher.imageJpegQuality, 80);
    expect(DocumentCapturePolicy.expenseVoucher.maxMegabytes, 5);
    expect(DocumentCapturePolicy.staffDocument.imageMaxDimension, 2000);
    expect(DocumentCapturePolicy.staffDocument.imageJpegQuality, 82);
    expect(DocumentCapturePolicy.courseResource.imageMaxDimension, 2000);
  });
}
