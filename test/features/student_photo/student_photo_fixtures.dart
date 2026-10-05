import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_scope.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_cipher.dart';
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
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_request.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../offline_full_db.dart';

class MockStudentPhotoApi extends Mock implements StudentPhotoApi {}

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

const String kSchool = 's-1';
const String kStudent = '6f1c2d3e-0000-4000-8000-000000000001';

/// Un faux JPEG : seuls ses octets comptent ici.
Uint8List photoBytes([int seed = 1]) =>
    Uint8List.fromList(List<int>.generate(64, (i) => (i * seed) % 251));

DioException httpError(int? status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: status,
          data: detailCode == null ? null : {'detailCode': detailCode},
        ),
);

void registerStudentPhotoFallbacks() {
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(StudentPhotoSize.thumb);
  registerFallbackValue(
    const StudentPhotoPushRequest(
      studentId: 'x',
      op: StudentPhotoOp.delete,
      at: 'x',
      authorId: 'x',
    ),
  );
}

/// Tout le module sur une base en mémoire et un magasin dans un dossier
/// temporaire, l'API simulée.
class StudentPhotoHarness {
  final Database db;
  final Directory base;
  final MockStudentPhotoApi api;
  final StudentPhotoBlobs blobs;
  final StudentPhotoChangeBus bus;
  final CurrentUserContext user;
  final StudentPhotoRepositoryImpl repository;
  final StudentPhotoOutboxHandler handler;
  final StudentPhotoFetcher fetcher;

  StudentPhotoHarness._({
    required this.db,
    required this.base,
    required this.api,
    required this.blobs,
    required this.bus,
    required this.user,
    required this.repository,
    required this.handler,
    required this.fetcher,
  });

  StudentPhotoDao get photos => StudentPhotoDao(db);

  static Future<StudentPhotoHarness> open() async {
    final db = await openFullOfflineDb();
    final base = await Directory.systemTemp.createTemp(
      'eteelo-student-photos-',
    );
    final api = MockStudentPhotoApi();
    final blobs = StudentPhotoBlobs(
      EncryptedBlobStore(
        directoryName: 'student_photos',
        keyService: _FakeKeyService(),
        cipher: runBlobCipherTask,
        baseDirectory: () async => base,
      ),
    );
    final bus = StudentPhotoChangeBus();
    final user = CurrentUserContext()..set('u-1', schoolId: kSchool);
    final fetcher = StudentPhotoFetcher(
      api: api,
      photos: StudentPhotoDao(db),
      blobs: blobs,
      tenant: const UnboundTenantScope(),
      extras: const {},
    );
    return StudentPhotoHarness._(
      db: db,
      base: base,
      api: api,
      blobs: blobs,
      bus: bus,
      user: user,
      fetcher: fetcher,
      repository: StudentPhotoRepositoryImpl(
        photos: StudentPhotoDao(db),
        writer: StudentPhotoWriteDao(db),
        blobs: blobs,
        fetcher: fetcher,
        bus: bus,
        currentUser: user,
        now: () => 1000,
      ),
      handler: StudentPhotoOutboxHandler(
        api: api,
        sync: StudentPhotoSyncDao(db),
        photos: StudentPhotoDao(db),
        blobs: blobs,
        bus: bus,
        currentUser: user,
        extras: const {},
        now: () => 2000,
      ),
    );
  }

  Future<void> close() async {
    await bus.dispose();
    await db.close();
    await base.delete(recursive: true);
  }

  Future<void> insertStudent(String id, {String syncStatus = 'SYNCED'}) =>
      db.insert('students', {
        'id': id,
        'first_name': 'Daniel',
        'last_name': 'Kabongo',
        'gender': 'MALE',
        'date_of_birth': '2015-01-01',
        'sync_status': syncStatus,
      });
}
