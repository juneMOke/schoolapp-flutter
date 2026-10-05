import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/class_roster_source.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';

import '../student_photo_fakes.dart';

class _MockRepository extends Mock implements StudentPhotoRepository {}

class _MockFiles extends Mock implements DocumentCaptureGateway {}

class _Rosters implements ClassRosterSource {
  @override
  Future<Either<Never, List<SessionClass>>> classes(String yearId) async =>
      const Right([
        SessionClass(id: 'c-6a', name: '6e A'),
        SessionClass(id: 'c-5b', name: '5e B'),
      ]);

  @override
  Future<Either<Never, List<SessionStudent>>> roster(String id) async => Right(
    id == 'c-6a'
        ? const [
            SessionStudent(id: 'kab', lastName: 'Kabongo', firstName: 'Daniel'),
            SessionStudent(id: 'muj', lastName: 'Mujinga', firstName: 'Esther'),
            SessionStudent(id: 'ama', lastName: 'Amani', firstName: 'Rose'),
          ]
        : const [
            SessionStudent(id: 'ngo', lastName: 'Ngoy', firstName: 'Paul'),
          ],
  );
}

const _back = CameraLens(name: 'back', facing: CameraFacing.back);

void main() {
  late _MockRepository repository;
  late _MockFiles files;
  late FakeCameras cameras;
  late FakeEncoder encoder;
  late PhotoSessionCubit cubit;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(DocumentCaptureMode.importImage);
  });

  setUp(() async {
    repository = _MockRepository();
    files = _MockFiles();
    cameras = FakeCameras([_back]);
    encoder = FakeEncoder();
    // « kab » a déjà sa photo ; « ngo » aussi : 5e B est complète.
    when(() => repository.loadIndex()).thenAnswer(
      (_) async => const Right({
        'kab': StudentPhotoRef(studentId: 'kab', version: 's:1'),
        'ngo': StudentPhotoRef(studentId: 'ngo', version: 's:2'),
      }),
    );
    when(
      () => repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    cubit = PhotoSessionCubit(
      rosters: _Rosters(),
      index: LoadStudentPhotoIndexUseCase(repository),
      save: SaveStudentPhotoUseCase(repository),
      encoder: encoder,
      cameras: cameras,
      files: files,
    );
    await cubit.load('y-1', isTouch: true);
  });
  tearDown(() => cubit.close());

  SessionShooting shooting() => cubit.state as SessionShooting;

  test('chaque classe dit combien d\'élèves n\'ont pas de photo', () {
    final setup = cubit.state as SessionSetup;
    expect(setup.classes.map((c) => c.missing), [2, 0]);
    expect(setup.classes.last.complete, isTrue);
    expect(setup.onlyMissing, isTrue);
  });

  test('« Commencer » compte les élèves du filtre', () {
    cubit.selectClass('c-6a');
    expect((cubit.state as SessionSetup).startCount, 2);
    cubit.setOnlyMissing(false);
    expect((cubit.state as SessionSetup).startCount, 3);
  });

  test('une classe complète avec le filtre ne démarre pas', () async {
    cubit.selectClass('c-5b');
    await cubit.start();
    expect(cubit.state, isA<SessionSetup>());
  });

  test('la file : sans photo d\'abord, puis l\'ordre alphabétique ; la caméra '
      's\'ouvre', () async {
    cubit
      ..selectClass('c-6a')
      ..setOnlyMissing(false);
    await cubit.start();
    expect(shooting().queue.map((i) => i.student.id), ['ama', 'muj', 'kab']);
    expect(shooting().camera, isA<CameraOpened>());
  });

  test('déclencher : recadrage automatique sur l\'ovale, photo gardée, '
      'flash ; puis l\'élève suivant', () async {
    cubit.selectClass('c-6a');
    await cubit.start();
    await cubit.shoot();

    expect(encoder.lastWindow, CropWindow.ovalGuide(400, 300));
    expect(shooting().flash, isNotNull);
    expect(shooting().queue.first.status, SessionItemStatus.photographed);
    verify(
      () => repository.savePhoto(
        studentId: 'ama',
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    ).called(1);

    await cubit.advance();
    expect(shooting().index, 1);
    expect(shooting().flash, isNull);
  });

  test('pas de second déclenchement pendant le flash', () async {
    cubit.selectClass('c-6a');
    await cubit.start();
    await cubit.shoot();
    await cubit.shoot();
    verify(
      () => repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    ).called(1);
  });

  test('« Reprendre » sur le flash : on reste sur l\'élève', () async {
    cubit.selectClass('c-6a');
    await cubit.start();
    await cubit.shoot();
    cubit.retakeCurrent();
    expect(shooting().index, 0);
    expect(shooting().current.status, SessionItemStatus.todo);
    expect(shooting().flash, isNull);
  });

  test('passer et absent avancent ; le dernier traité mène au bilan', () async {
    cubit.selectClass('c-6a');
    await cubit.start();
    await cubit.skip();
    expect(shooting().index, 1);
    await cubit.markAbsent();

    final summary = cubit.state as SessionSummary;
    expect(summary.absent, 1);
    expect(summary.skipped, 1);
    expect(summary.resumable, 2);
    expect(cameras.opened.single.closed, isTrue);
  });

  test('un élève photographié est inerte dans la file', () async {
    cubit.selectClass('c-6a');
    await cubit.start();
    await cubit.shoot();
    await cubit.advance();
    cubit.select(0);
    expect(shooting().index, 1);
  });

  test('reprendre absents & passés les remet à photographier', () async {
    cubit.selectClass('c-6a');
    await cubit.start();
    await cubit.shoot();
    await cubit.advance();
    await cubit.markAbsent();
    await cubit.resume();

    expect(shooting().current.student.id, 'muj');
    expect(shooting().queue.first.status, SessionItemStatus.photographed);
    expect(cameras.opened, hasLength(2));
  });

  test('sans caméra, la séance continue à l\'import', () async {
    cameras.available = const [];
    when(
      () => files.acquire(any()),
    ).thenAnswer((_) async => RawCapture(bytes: Uint8List.fromList([1, 2])));
    cubit.selectClass('c-6a');
    await cubit.start();
    expect(shooting().camera, isA<CameraUnavailable>());

    await cubit.importForCurrent();
    expect(encoder.lastWindow, CropWindow.centered(400, 300));
    expect(shooting().queue.first.status, SessionItemStatus.photographed);
  });
}
