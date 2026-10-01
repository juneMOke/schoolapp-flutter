import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_cipher.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_key_service.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_models.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_session_guard.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_document_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_push_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_transfer_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

class _MockApi extends Mock implements StaffDocumentTransferApi {}

class _MockAuth extends Mock implements AuthLocalDao {}

class _MockUser extends Mock implements AuthLocalUserRecord {}

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

DioException _http(int status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: detailCode == null ? null : {'detailCode': detailCode},
  ),
);

final _bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

void main() {
  late Database db;
  late Directory base;
  late EncryptedBlobStore store;
  late _MockApi api;
  late CurrentUserContext user;
  late StaffDocumentRepositoryImpl repo;
  late StaffDocumentOutboxHandler handler;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      const StaffDocumentUploadDto(
        id: 'x',
        staffMemberId: 'x',
        code: 'x',
        source: 'x',
        capturedAt: 'x',
        mimeType: 'x',
        sizeBytes: 0,
        sha256: 'x',
        authorId: 'x',
      ),
    );
  });

  setUp(() async {
    db = await openFullOfflineDb();
    base = await Directory.systemTemp.createTemp('eteelo-staff-documents-');
    store = EncryptedBlobStore(
      directoryName: 'staff_documents',
      keyService: _FakeKeyService(),
      cipher: runBlobCipherTask,
      baseDirectory: () async => base,
    );
    api = _MockApi();
    user = CurrentUserContext()..set('u-1', schoolId: 's-1');
    repo = StaffDocumentRepositoryImpl(
      documents: StaffDocumentDao(db),
      types: StaffDocumentTypeDao(db),
      writer: StaffDocumentWriteDao(db),
      sync: StaffDocumentSyncDao(db),
      api: api,
      store: store,
      currentUser: user,
      ids: const IdGenerator(Uuid()),
      extras: const {},
      now: () => DateTime.utc(2026, 9, 29, 8),
    );
    handler = StaffDocumentOutboxHandler(
      api: api,
      dao: StaffDocumentSyncDao(db),
      members: StaffMemberDao(db),
      store: store,
      currentUser: user,
      extras: const {},
      now: () => 42,
    );
  });
  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  Future<CapturedDocument> captured() async => CapturedDocument(
    bytes: _bytes,
    mimeType: DocumentMimeType.pdf,
    source: DocumentCaptureSource.import,
    sha256Hex: await sha256Hex(_bytes),
    capturedAt: DateTime.utc(2026, 9, 29, 7),
    fileName: 'diplome.pdf',
  );

  Future<void> seedAckedMember() => StaffMemberDao(db).applyPulled(
    [StaffMemberDeltaDto.tryParse(staffMemberJson('m-1'))!],
    schoolId: 's-1',
    nowMs: 1,
  );

  Future<OutboxEntry> entry() async =>
      (await OutboxDao(db).pendingAll()).single;

  Future<Map<String, Object?>> row() async =>
      (await db.query('staff_documents')).single;

  test('verser scelle les octets, écrit la pièce et UNE entrée', () async {
    expect(
      (await repo.addDocument('m-1', 'DIPLOMA', await captured())).isRight(),
      isTrue,
    );

    final written = await row();
    expect(written['sync_status'], 'PENDING_SYNC');
    expect(written['source'], 'IMPORT');
    expect(written['mime_type'], 'application/pdf');
    final queued = await entry();
    expect(queued.id, 'STAFF_DOCUMENT:${written['id']}');
    final payload = StaffDocumentUploadDto.tryParse(
      jsonDecode(queued.payload),
    )!;
    expect(payload.toMetadata().containsKey('staffMemberId'), isFalse);
    expect(payload.sha256, written['sha256']);
    expect(await store.read(written['id']! as String), isA<BlobFound>());
  });

  test('sans session, ni octets ni ligne', () async {
    user.clear();

    final result = await repo.addDocument('m-1', 'ID', await captured());

    expect(result.fold((f) => f, (_) => null), isA<AuthFailure>());
    expect(await db.query('staff_documents'), isEmpty);
  });

  group('handler', () {
    setUp(() async => repo.addDocument('m-1', 'ID', await captured()));

    test('bloquée par la fiche tant qu elle n est pas accusée', () async {
      await db.insert('staff_members', {
        'id': 'm-1',
        'school_id': 's-1',
        'last_name': 'K',
        'first_name': 'J',
        'category': 'TEACHER',
        'sync_status': 'PENDING_SYNC',
      });

      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.blocked,
      );
      verifyNever(() => api.upload(any(), any(), any()));
    });

    test('accusé : la pièce devient celle du serveur, octets gardés', () async {
      await seedAckedMember();
      final id = (await row())['id']! as String;
      when(() => api.upload(any(), any(), any())).thenAnswer(
        (_) async => StaffDocumentDeltaDto.tryParse(staffDocumentJson(id))!,
      );

      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.acked,
      );
      expect((await row())['sync_status'], 'SYNCED');
      final sent = verify(
        () => api.upload(any(), any(), captureAny()),
      ).captured.single;
      expect(sent, _bytes);
      expect(await store.read(id), isA<BlobFound>());
    });

    test('409 attend la fiche, 422 refuse, 410 efface', () async {
      await seedAckedMember();
      final id = (await row())['id']! as String;
      when(
        () => api.upload(any(), any(), any()),
      ).thenThrow(_http(409, detailCode: 'STAFF_MEMBER_NOT_YET_SYNCED'));
      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.blocked,
      );

      when(
        () => api.upload(any(), any(), any()),
      ).thenThrow(_http(422, detailCode: 'DOCUMENT_TOO_LARGE'));
      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.failed,
      );
      expect((await row())['sync_error_code'], 'DOCUMENT_TOO_LARGE');

      when(() => api.upload(any(), any(), any())).thenThrow(_http(410));
      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.acked,
      );
      expect(await db.query('staff_documents'), isEmpty);
      expect(await store.read(id), isA<BlobGone>());
    });

    test('déjà accusée par la descente : rien ne repart', () async {
      await seedAckedMember();
      final id = (await row())['id']! as String;
      await StaffDocumentDao(db).applyPulled(
        [StaffDocumentDeltaDto.tryParse(staffDocumentJson(id))!],
        schoolId: 's-1',
        nowMs: 2,
      );
      await store.delete(id);

      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.acked,
      );
      expect((await row())['sync_status'], 'SYNCED');
      verifyNever(() => api.upload(any(), any(), any()));
    });

    test('fiche purgée : la pièce le dit et ses octets partent', () async {
      final id = (await row())['id']! as String;

      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.failed,
      );
      expect(
        (await row())['sync_error_code'],
        StaffDocumentOutboxHandler.memberGoneCode,
      );
      expect(await store.read(id), isA<BlobGone>());
    });

    test('octets perdus : refusée sans appel, et dit pourquoi', () async {
      await seedAckedMember();
      await store.delete((await row())['id']! as String);

      expect(
        (await handler.dispatch(await entry())).outcome,
        OutboxDispatchOutcome.failed,
      );
      expect(
        (await row())['sync_error_code'],
        StaffDocumentOutboxHandler.bytesLostCode,
      );
      verifyNever(() => api.upload(any(), any(), any()));
    });
  });

  group('ouvrir', () {
    Future<void> seedPulled(String sha) => StaffDocumentDao(db).applyPulled(
      [
        StaffDocumentDeltaDto.tryParse({
          ...staffDocumentJson('d-1'),
          'sha256': sha,
          'mimeType': 'application/pdf',
        })!,
      ],
      schoolId: 's-1',
      nowMs: 1,
    );

    Future<Object?> open() async {
      final document = (await StaffDocumentDao(
        db,
      ).forMember('m-1')).single.toEntity();
      return (await repo.open(document)).fold((f) => f, (c) => c.bytes);
    }

    test('absente du poste : demandée, vérifiée, gardée', () async {
      await seedPulled(await sha256Hex(_bytes));
      when(() => api.download(any(), any())).thenAnswer((_) async => _bytes);

      expect(await open(), _bytes);
      expect(await open(), _bytes);
      verify(() => api.download(any(), any())).called(1);
    });

    test(
      'des octets à l empreinte différente ne sont ni montrés ni gardés',
      () async {
        await seedPulled('00' * 32);
        when(() => api.download(any(), any())).thenAnswer((_) async => _bytes);

        expect(await open(), isA<IntegrityFailure>());
        expect(await store.read('d-1'), isA<BlobGone>());
      },
    );

    test('hors ligne : échec réseau, sans exception', () async {
      await seedPulled(await sha256Hex(_bytes));
      when(
        () => api.download(any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));

      expect(await open(), isA<NetworkFailure>());
    });
  });

  group('garde de session', () {
    late _MockAuth auth;
    late _MockUser account;
    late StaffDocumentSessionGuard guard;

    setUp(() async {
      auth = _MockAuth();
      account = _MockUser();
      when(() => auth.getSessionUser()).thenAnswer((_) async => account);
      guard = StaffDocumentSessionGuard(
        store: store,
        documents: StaffDocumentSyncDao(db),
        authLocalDao: auth,
      );
      await StaffDocumentDao(db).applyPulled(
        [StaffDocumentDeltaDto.tryParse(staffDocumentJson('d-1'))!],
        schoolId: 's-1',
        nowMs: 1,
      );
      await store.stage(id: 'd-1', bytes: _bytes);
      await store.commit('d-1');
      await repo.addDocument('m-1', 'ID', await captured());
    });

    test('les copies refusées partent aussi', () async {
      when(() => account.permissions).thenReturn(const ['hr.staff.read']);
      await db.update(
        'staff_documents',
        {'sync_status': 'SYNC_ERROR'},
        where: 'id = ?',
        whereArgs: ['d-1'],
      );

      expect(await guard.onSessionOpened(), 1);
      expect(await store.read('d-1'), isA<BlobGone>());
    });

    test('un compte sans le droit efface les copies accusées seules', () async {
      when(() => account.permissions).thenReturn(const ['hr.staff.read']);
      final pendingId =
          (await db.query(
                'staff_documents',
                where: 'sync_status = ?',
                whereArgs: [RecordSyncState.pending.dbValue],
              )).single['id']!
              as String;

      expect(await guard.onSessionOpened(), 1);
      expect(await store.read('d-1'), isA<BlobGone>());
      expect(await store.read(pendingId), isA<BlobFound>());
    });

    test('droit présent ou inconnu : rien n est effacé', () async {
      when(() => account.permissions).thenReturn(const ['hr.document.read']);
      expect(await guard.onSessionOpened(), 0);
      when(() => account.permissions).thenReturn(null);
      expect(await guard.onSessionOpened(), 0);
      expect(await store.read('d-1'), isA<BlobFound>());
    });
  });
}
