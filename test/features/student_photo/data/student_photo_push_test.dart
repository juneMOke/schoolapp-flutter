import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/crypto/sha256_hex.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_write_dao.dart';
import 'package:school_app_flutter/features/student_photo/data/repositories/student_photo_repository_impl.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_dto.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_outbox_handler.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

import '../student_photo_fixtures.dart';

final DateTime _takenAt = DateTime.utc(2026, 10, 5, 8, 14, 3, 120, 456);
const String _takenAtWire = '2026-10-05T08:14:03.120Z';

void main() {
  late StudentPhotoHarness h;

  setUpAll(registerStudentPhotoFallbacks);

  setUp(() async {
    h = await StudentPhotoHarness.open();
  });
  tearDown(() => h.close());

  Future<OutboxEntry> entry() async =>
      (await OutboxDao(h.db).byId(StudentPhotoWriteDao.entryId(kStudent)))!;

  Future<StudentPhotoLocalModel> row() async =>
      (await h.photos.find(kStudent))!;

  Future<String> save([int seed = 1, DateTime? at]) async {
    final bytes = photoBytes(seed);
    final result = await h.repository.savePhoto(
      studentId: kStudent,
      jpeg: bytes,
      takenAt: at ?? _takenAt,
    );
    expect(result.isRight(), isTrue);
    return sha256Hex(bytes);
  }

  void serverAnswers({String? sha256, String takenAt = _takenAtWire}) {
    final state = StudentPhotoStateDto(
      studentId: kStudent,
      sha256: sha256,
      takenAt: takenAt,
      serverUpdatedAt: '2026-10-05T08:14:05.402Z',
    );
    when(() => h.api.put(any(), any(), any())).thenAnswer((_) async => state);
    when(() => h.api.delete(any(), any())).thenAnswer((_) async => state);
  }

  group('le geste local', () {
    test('une prise écrit ses octets, sa ligne et son entrée d\'outbox, '
        'datée à la milliseconde', () async {
      final sha = await save();

      final saved = await row();
      expect(saved.pendingOp, StudentPhotoOp.put);
      expect(saved.pendingSha256, sha);
      expect(saved.pendingAt, _takenAtWire);
      expect(saved.syncState, RecordSyncState.pending);
      final payload = jsonDecode((await entry()).payload) as Map;
      expect(payload['at'], _takenAtWire);
      expect(payload['sha256'], sha);
      expect(payload['authorId'], 'u-1');
      expect(await h.blobs.readPending(kStudent, sha), isA<BlobFound>());
    });

    test('la photo prise se montre aussitôt, sans réseau', () async {
      await save();
      final index = (await h.repository.loadIndex()).getOrElse(() => {});
      final ref = index[kStudent]!;
      expect(ref.hasPhoto, isTrue);
      expect(ref.isPending, isTrue);
      final bytes = await h.repository.bytesOf(ref, StudentPhotoSize.thumb);
      expect(bytes.getOrElse(() => null), photoBytes());
      verifyNever(() => h.api.download(any(), any(), any()));
    });

    test('une seconde prise remplace la première : une seule entrée, et les '
        'octets de la première sont effacés', () async {
      final first = await save(1);
      final second = await save(2, _takenAt.add(const Duration(seconds: 5)));

      expect(await OutboxDao(h.db).pendingCount(), 1);
      final payload = jsonDecode((await entry()).payload) as Map;
      expect(payload['sha256'], second);
      expect(await h.blobs.readPending(kStudent, first), isA<BlobGone>());
    });

    test('un retrait masque la photo et part en file', () async {
      await save();
      final result = await h.repository.removePhoto(
        studentId: kStudent,
        removedAt: _takenAt.add(const Duration(minutes: 1)),
      );
      expect(result.isRight(), isTrue);
      final ref = (await row()).toRef();
      expect(ref.hasPhoto, isFalse);
      expect(ref.isPending, isTrue);
      final payload = jsonDecode((await entry()).payload) as Map;
      expect(payload['op'], 'DELETE');
    });

    test('le bus annonce l\'élève touché', () async {
      final seen = expectLater(h.bus.stream, emits({kStudent}));
      await save();
      await seen;
    });
  });

  group('l\'envoi', () {
    test('attend l\'accusé d\'une inscription saisie sur le poste', () async {
      for (final status in ['DRAFT', 'PENDING_SYNC', 'SYNC_ERROR']) {
        await h.db.delete('students');
        await h.insertStudent(kStudent, syncStatus: status);
        await save();
        final result = await h.handler.dispatch(await entry());
        expect(result.outcome, OutboxDispatchOutcome.blocked, reason: status);
      }
      verifyNever(() => h.api.put(any(), any(), any()));
    });

    test('accusé de notre prise : la photo envoyée devient la copie '
        'd\'affichage, ses octets en attente partent', () async {
      await h.insertStudent(kStudent);
      final sha = await save();
      serverAnswers(sha256: 'server-sha');

      final result = await h.handler.dispatch(await entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final settled = await row();
      expect(settled.sha256, 'server-sha');
      expect(settled.pendingOp, isNull);
      expect(settled.syncState, RecordSyncState.synced);
      expect(settled.cachedShaOf(StudentPhotoSize.full), 'server-sha');
      expect(settled.toRef().version, 's:server-sha');
      expect(await h.blobs.readPending(kStudent, sha), isA<BlobGone>());
      final cached = await h.blobs.readCache(kStudent, StudentPhotoSize.full);
      expect((cached as BlobFound).blob.bytes, photoBytes());
    });

    test('un élève que le poste ne porte pas (cohorte N-1) part sans '
        'attendre', () async {
      await save();
      serverAnswers(sha256: 'server-sha');
      final result = await h.handler.dispatch(await entry());
      expect(result.outcome, OutboxDispatchOutcome.acked);
    });

    test('une prise plus récente gardée par le serveur : la nôtre n\'est pas '
        'mise en copie', () async {
      final sha = await save();
      serverAnswers(sha256: 'newer', takenAt: '2026-10-05T09:00:00.000Z');

      await h.handler.dispatch(await entry());

      final settled = await row();
      expect(settled.sha256, 'newer');
      expect(settled.pendingOp, isNull);
      expect(settled.cachedShaOf(StudentPhotoSize.full), isNull);
      expect(await h.blobs.readPending(kStudent, sha), isA<BlobGone>());
    });

    test(
      'un geste posé pendant l\'envoi survit à l\'accusé du précédent',
      () async {
        await save(1);
        final inFlight = await entry();
        late String newer;
        when(() => h.api.put(any(), any(), any())).thenAnswer((_) async {
          newer = await save(2, _takenAt.add(const Duration(seconds: 9)));
          return const StudentPhotoStateDto(
            studentId: kStudent,
            sha256: 'server-sha',
            takenAt: _takenAtWire,
          );
        });

        await h.handler.dispatch(inFlight);

        final after = await row();
        expect(after.sha256, 'server-sha');
        expect(after.pendingSha256, newer);
        expect(after.syncState, RecordSyncState.pending);
        expect(await h.blobs.readPending(kStudent, newer), isA<BlobFound>());
      },
    );

    test('un geste déjà soldé est acquitté sans rien renvoyer', () async {
      await save();
      final stale = await entry();
      await h.db.update('student_photos', {'pending_op': null});
      final result = await h.handler.dispatch(stale);
      expect(result.outcome, OutboxDispatchOutcome.acked);
      verifyNever(() => h.api.put(any(), any(), any()));
    });

    test('refus 422 : le geste est abandonné, sa raison gardée, ses octets '
        'effacés', () async {
      final sha = await save();
      when(
        () => h.api.put(any(), any(), any()),
      ).thenThrow(httpError(422, detailCode: 'PHOTO_NOT_SQUARE'));

      final result = await h.handler.dispatch(await entry());

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final rejected = await row();
      expect(rejected.pendingOp, isNull);
      expect(rejected.syncState, RecordSyncState.failed);
      expect(rejected.toRef().rejection, contains('PHOTO_NOT_SQUARE'));
      expect(await h.blobs.readPending(kStudent, sha), isA<BlobGone>());
    });

    test('404 pour un élève que le poste porte : on attend', () async {
      await h.insertStudent(kStudent);
      await save();
      when(
        () => h.api.put(any(), any(), any()),
      ).thenThrow(httpError(404, detailCode: 'STUDENT_NOT_FOUND'));
      final result = await h.handler.dispatch(await entry());
      expect(result.outcome, OutboxDispatchOutcome.blocked);
      expect((await row()).pendingOp, StudentPhotoOp.put);
    });

    test('404 pour un élève disparu du poste : photo orpheline, refusée et '
        'effacée', () async {
      final sha = await save();
      when(
        () => h.api.put(any(), any(), any()),
      ).thenThrow(httpError(404, detailCode: 'STUDENT_NOT_FOUND'));
      final result = await h.handler.dispatch(await entry());
      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(await h.blobs.readPending(kStudent, sha), isA<BlobGone>());
    });

    test('transport, 5xx, 401 et 429 se rejouent', () async {
      await save();
      for (final status in [null, 503, 401, 429]) {
        when(() => h.api.put(any(), any(), any())).thenThrow(httpError(status));
        final result = await h.handler.dispatch(await entry());
        expect(result.outcome, OutboxDispatchOutcome.retry, reason: '$status');
      }
      expect((await row()).pendingOp, StudentPhotoOp.put);
    });

    test('des octets perdus ne partiront jamais', () async {
      final sha = await save();
      await h.blobs.deletePending(kStudent, sha);
      final result = await h.handler.dispatch(await entry());
      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(
        (await row()).row['sync_error_code'],
        StudentPhotoOutboxHandler.bytesLostCode,
      );
    });

    test('accusé d\'un retrait : les copies d\'affichage partent', () async {
      await h.blobs.writeCache(kStudent, StudentPhotoSize.thumb, photoBytes());
      await h.photos.applyPulled(
        [const StudentPhotoStateDto(studentId: kStudent, sha256: 'old')],
        schoolId: kSchool,
        nowMs: 1,
      );
      await h.photos.markCached(
        kStudent,
        StudentPhotoSize.thumb,
        sha256: 'old',
      );
      await h.repository.removePhoto(studentId: kStudent, removedAt: _takenAt);
      serverAnswers();

      final result = await h.handler.dispatch(await entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final settled = await row();
      expect(settled.sha256, isNull);
      expect(settled.cachedShaOf(StudentPhotoSize.thumb), isNull);
      expect(
        await h.blobs.readCache(kStudent, StudentPhotoSize.thumb),
        isA<BlobGone>(),
      );
    });
  });

  test('l\'instant part en UTC, à la milliseconde', () {
    expect(
      StudentPhotoRepositoryImpl.wireInstant(
        DateTime.utc(2026, 1, 2, 3, 4, 5, 6, 7),
      ),
      '2026-01-02T03:04:05.006Z',
    );
    expect(
      StudentPhotoOutboxHandler.sameInstant(
        '2026-10-05T08:14:03.120456Z',
        '2026-10-05T08:14:03.120Z',
      ),
      isTrue,
    );
  });
}
