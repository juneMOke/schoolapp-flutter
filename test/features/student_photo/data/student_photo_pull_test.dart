import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/blob_read.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_api.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_dto.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_puller.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';

import '../student_photo_fixtures.dart';

StudentPhotoPageDto _page(List<Map<String, Object?>> items) =>
    StudentPhotoPageDto.fromJson({
      'items': items,
      'hasMore': false,
      'nextWatermark': 'w-1',
      'serverTime': '2026-10-05T08:00:00Z',
    });

void main() {
  late StudentPhotoHarness h;
  late StudentPhotoPuller puller;

  setUpAll(registerStudentPhotoFallbacks);

  setUp(() async {
    h = await StudentPhotoHarness.open();
    puller = StudentPhotoPuller(
      api: h.api,
      runner: KeysetPullRunner(SyncMetaDao(h.db)),
      photos: h.photos,
      blobs: h.blobs,
      fetcher: h.fetcher,
      bus: h.bus,
      currentUser: h.user,
      requiredAuth: const {},
    );
  });
  tearDown(() => h.close());

  Future<StudentPhotoLocalModel> row() async =>
      (await h.photos.find(kStudent))!;

  void pageOf(List<Map<String, Object?>> items) => when(
    () => h.api.pull(any(), any(), any()),
  ).thenAnswer((_) async => _page(items));

  void thumbnailServed() =>
      when(() => h.api.download(any(), any(), any())).thenAnswer(
        (_) async => StudentPhotoDownload(bytes: photoBytes(3), etag: 'sha-a'),
      );

  test('la descente range la photo et précharge sa vignette', () async {
    pageOf([
      {
        'studentId': kStudent,
        'sha256': 'SHA-A',
        'takenAt': '2026-10-05T08:14:03Z',
      },
    ]);
    thumbnailServed();

    final result = await puller.pull();
    await puller.prefetchThumbnails(kSchool);

    expect(result.isRight(), isTrue);
    expect((await row()).sha256, 'sha-a');
    expect((await row()).cachedShaOf(StudentPhotoSize.thumb), 'sha-a');
    expect(
      await h.blobs.readCache(kStudent, StudentPhotoSize.thumb),
      isA<BlobFound>(),
    );
  });

  test('le curseur est scopé par école', () async {
    pageOf([]);
    await puller.pull();
    expect(
      await SyncMetaDao(h.db).getCursor(StudentPhotoPuller.cursorKey(kSchool)),
      'w-1',
    );
  });

  test('une descente ne touche pas au geste en attente', () async {
    await h.repository.savePhoto(
      studentId: kStudent,
      jpeg: photoBytes(),
      takenAt: DateTime.utc(2026, 10, 5),
    );
    pageOf([
      {'studentId': kStudent, 'sha256': 'sha-b'},
    ]);
    when(() => h.api.download(any(), any(), any())).thenThrow(httpError(null));

    await puller.pull();

    final after = await row();
    expect(after.sha256, 'sha-b');
    expect(after.pendingOp, StudentPhotoOp.put);
    expect(after.toRef().isPending, isTrue);
  });

  test('une photo retirée côté serveur efface la copie du poste', () async {
    await h.photos.applyPulled(
      [const StudentPhotoStateDto(studentId: kStudent, sha256: 'old')],
      schoolId: kSchool,
      nowMs: 1,
    );
    await h.blobs.writeCache(kStudent, StudentPhotoSize.thumb, photoBytes());
    await h.photos.markCached(kStudent, StudentPhotoSize.thumb, sha256: 'old');
    pageOf([
      {'studentId': kStudent, 'sha256': null},
    ]);

    await puller.pull();

    expect((await row()).toRef().hasPhoto, isFalse);
    expect((await row()).cachedShaOf(StudentPhotoSize.thumb), isNull);
    expect(
      await h.blobs.readCache(kStudent, StudentPhotoSize.thumb),
      isA<BlobGone>(),
    );
  });

  test('une ligne sans élève est écartée, pas levée', () {
    final page = StudentPhotoPageDto.fromJson({
      'items': [
        {'sha256': 'x'},
        {'studentId': kStudent},
      ],
      'hasMore': false,
      'serverTime': '2026-10-05T08:00:00Z',
    });
    expect(page.items, hasLength(1));
    expect(page.skipped, 1);
  });

  group('l\'affichage', () {
    setUp(() async {
      await h.photos.applyPulled(
        [const StudentPhotoStateDto(studentId: kStudent, sha256: 'sha-a')],
        schoolId: kSchool,
        nowMs: 1,
      );
    });

    Future<Object?> read(StudentPhotoSize size) async {
      final ref = (await row()).toRef();
      return (await h.repository.bytesOf(ref, size)).getOrElse(() => null);
    }

    test('télécharge une fois, puis relit la copie', () async {
      thumbnailServed();
      expect(await read(StudentPhotoSize.thumb), photoBytes(3));
      expect(await read(StudentPhotoSize.thumb), photoBytes(3));
      verify(
        () => h.api.download(any(), kStudent, StudentPhotoSize.thumb),
      ).called(1);
    });

    test('une copie d\'une autre empreinte n\'est pas gardée', () async {
      when(() => h.api.download(any(), any(), any())).thenAnswer(
        (_) async => StudentPhotoDownload(bytes: photoBytes(3), etag: 'sha-z'),
      );
      expect(await read(StudentPhotoSize.thumb), photoBytes(3));
      expect((await row()).cachedShaOf(StudentPhotoSize.thumb), isNull);
    });

    test('la vignette se tire de la grande copie', () async {
      await h.blobs.writeCache(kStudent, StudentPhotoSize.full, photoBytes(5));
      await h.photos.markCached(
        kStudent,
        StudentPhotoSize.full,
        sha256: 'sha-a',
      );
      expect(await read(StudentPhotoSize.thumb), photoBytes(5));
      verifyNever(() => h.api.download(any(), any(), any()));
    });

    test(
      'hors ligne : la vignette faute de grande photo, sinon rien',
      () async {
        when(
          () => h.api.download(any(), any(), any()),
        ).thenThrow(httpError(null));
        expect(await read(StudentPhotoSize.full), isNull);
        await h.blobs.writeCache(
          kStudent,
          StudentPhotoSize.thumb,
          photoBytes(7),
        );
        await h.photos.markCached(
          kStudent,
          StudentPhotoSize.thumb,
          sha256: 'sha-a',
        );
        expect(await read(StudentPhotoSize.full), photoBytes(7));
      },
    );

    test('une copie disparue du magasin perd sa marque', () async {
      await h.photos.markCached(
        kStudent,
        StudentPhotoSize.thumb,
        sha256: 'sha-a',
      );
      thumbnailServed();
      expect(await read(StudentPhotoSize.thumb), photoBytes(3));
      verify(() => h.api.download(any(), any(), any())).called(1);
    });
  });

  test('la page vide en fin de cycle n\'est pas une erreur', () {
    final page = _page([]);
    expect(page, isA<KeysetPageDto<StudentPhotoStateDto>>());
    expect(page.items, isEmpty);
  });
}
