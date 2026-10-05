import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';

import '../student_photo_fakes.dart';

class _MockRepository extends Mock implements StudentPhotoRepository {}

class _MockFiles extends Mock implements DocumentCaptureGateway {}

const _front = CameraLens(name: 'front', facing: CameraFacing.front);
const _back = CameraLens(name: 'back', facing: CameraFacing.back);

void main() {
  late _MockRepository repository;
  late _MockFiles files;
  late FakeCameras cameras;
  late FakeEncoder encoder;
  late StudentPhotoCaptureCubit cubit;
  final at = DateTime.utc(2026, 10, 5, 8);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(DocumentCaptureMode.importImage);
  });

  setUp(() {
    repository = _MockRepository();
    files = _MockFiles();
    cameras = FakeCameras([_front, _back]);
    encoder = FakeEncoder();
    when(
      () => repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    cubit = StudentPhotoCaptureCubit(
      cameras: cameras,
      files: files,
      encoder: encoder,
      save: SaveStudentPhotoUseCase(repository),
      now: () => at,
    );
  });
  tearDown(() => cubit.close());

  test(
    'tablette : la caméra arrière d\'abord ; bascule vers l\'avant',
    () async {
      await cubit.start(target: const SaveForStudent('s-1'), isTouch: true);
      final live = cubit.state as CaptureLive;
      expect(live.session.lens, _back);
      expect(live.canSwitch, isTrue);

      await cubit.switchCamera();
      expect((cubit.state as CaptureLive).session.lens, _front);
      expect(cameras.opened.first.closed, isTrue);
    },
  );

  test('poste : la webcam avant d\'abord', () async {
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    expect((cubit.state as CaptureLive).session.lens, _front);
  });

  test('aucune caméra, ou caméra refusée : bloqué, l\'import reste', () async {
    cameras.available = const [];
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: true);
    expect(cubit.state, const CaptureBlocked(CameraBlockReason.none));

    cameras
      ..available = const [_back]
      ..openError = const CameraAccessDeniedException();
    await cubit.reopenCamera();
    expect(cubit.state, const CaptureBlocked(CameraBlockReason.denied));
  });

  test('déclencher : la caméra s\'éteint, le recadrage part du guide ovale, '
      'datée au déclenchement', () async {
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    await cubit.shoot();

    final review = cubit.state as CaptureReview;
    expect(review.origin, PhotoOrigin.camera);
    expect(review.mirror, isTrue, reason: 'caméra frontale');
    expect(review.window, CropWindow.ovalGuide(400, 300));
    expect(review.takenAt, at);
    expect(cameras.opened.single.closed, isTrue);
  });

  test('utiliser : le carré est enregistré pour l\'élève', () async {
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    await cubit.shoot();
    await cubit.confirm();

    expect(cubit.state, isA<CaptureSaved>());
    expect(encoder.lastMirror, isTrue);
    verify(
      () => repository.savePhoto(
        studentId: 's-1',
        jpeg: any(named: 'jpeg'),
        takenAt: at,
      ),
    ).called(1);
  });

  test('nouvelle inscription : la photo est rendue en brouillon, rien n\'est '
      'enregistré', () async {
    await cubit.start(target: const KeepAsDraft(), isTouch: false);
    await cubit.shoot();
    await cubit.confirm();

    expect(cubit.state, isA<CaptureDraftReady>());
    verifyNever(
      () => repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    );
  });

  test('un enregistrement raté garde la photo pour réessayer', () async {
    when(
      () => repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('disque')));
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    await cubit.shoot();
    await cubit.confirm();

    expect(cubit.state, isA<CaptureSaveFailed>());
  });

  test('importer : recadrage centré, sans miroir', () async {
    when(
      () => files.acquire(any()),
    ).thenAnswer((_) async => RawCapture(bytes: Uint8List.fromList([1, 2, 3])));
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    await cubit.importFile();

    final review = cubit.state as CaptureReview;
    expect(review.origin, PhotoOrigin.file);
    expect(review.mirror, isFalse);
    expect(review.window, CropWindow.centered(400, 300));
  });

  test('un fichier illisible ou trop lourd est refusé', () async {
    encoder.unreadable = true;
    when(
      () => files.acquire(any()),
    ).thenAnswer((_) async => RawCapture(bytes: Uint8List.fromList([1])));
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    await cubit.importFile();
    expect(cubit.state, const CaptureBadFile());

    encoder.unreadable = false;
    when(() => files.acquire(any())).thenAnswer(
      (_) async => RawCapture(
        bytes: Uint8List(StudentPhotoCaptureCubit.maxImportBytes + 1),
      ),
    );
    await cubit.importFile();
    expect(cubit.state, const CaptureBadFile());
  });

  test('renoncer au sélecteur laisse la caméra en direct', () async {
    when(() => files.acquire(any())).thenAnswer((_) async => null);
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    await cubit.importFile();
    expect(cubit.state, isA<CaptureLive>());
  });

  test(
    'ouvrir par l\'import puis y renoncer : la caméra prend le relais',
    () async {
      when(() => files.acquire(any())).thenAnswer((_) async => null);
      await cubit.start(
        target: const SaveForStudent('s-1'),
        isTouch: false,
        importFirst: true,
      );
      expect(cubit.state, isA<CaptureLive>());
    },
  );

  test('recadrer une photo existante ouvre directement le recadrage', () async {
    await cubit.start(
      target: const SaveForStudent('s-1'),
      isTouch: false,
      recrop: Uint8List.fromList([1]),
    );
    expect(cubit.state, isA<CaptureReview>());
    expect(cameras.opened, isEmpty);
  });

  test('fermer la modale éteint la caméra', () async {
    await cubit.start(target: const SaveForStudent('s-1'), isTouch: false);
    await cubit.close();
    expect(cameras.opened.single.closed, isTrue);
  });
}
