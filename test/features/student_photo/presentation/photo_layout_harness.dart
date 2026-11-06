import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/class_roster_source.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/load_photo_session_classes_use_case.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_network_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../student_photo_fakes.dart';
import '../student_photo_test_module.dart';

/// Banc d'essai des écrans de prise de vue : la modale de capture et la
/// séance, montées pour de vrai sur des caméras simulées.

class _MockRepository extends Mock implements StudentPhotoRepository {}

class _MockFiles extends Mock implements DocumentCaptureGateway {}

class _MockYear
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockNetwork extends MockCubit<bool> implements PhotoNetworkCubit {}

class _Rosters implements ClassRosterSource {
  @override
  Future<Either<Never, List<SessionClass>>> classes(String yearId) async =>
      const Right([SessionClass(id: 'c-6a', name: '6e A')]);

  @override
  Future<Either<Never, List<SessionStudent>>> roster(String id) async =>
      const Right([
        SessionStudent(id: 'ama', lastName: 'Amani', firstName: 'Rose'),
        SessionStudent(id: 'muj', lastName: 'Mujinga', firstName: 'Esther'),
      ]);
}

const backLens = CameraLens(name: 'back', facing: CameraFacing.back);

/// Le second objectif d'un vrai téléphone : « Changer de caméra » apparaît.
const frontLens = CameraLens(name: 'front', facing: CameraFacing.front);

/// Les formats de référence (AGENTS.md § « Écran neuf »), plus les deux
/// portables et le téléphone en paysage.
const referenceFormats = <Size>[
  Size(360, 740),
  Size(740, 360),
  Size(600, 960),
  Size(960, 600),
  Size(800, 1280),
  Size(1280, 800),
  Size(1366, 768),
  Size(1440, 900),
  Size(1920, 1080),
];

class PhotoLayoutHarness {
  /// Neuves à chaque test : un refus simulé ne fuit pas dans le suivant.
  FakeCameras cameras = FakeCameras([backLens]);
  final _MockRepository _repository = _MockRepository();
  final DocumentCaptureGateway files = _MockFiles();
  late Future<void> Function() _unregister;

  static void registerFallbacks() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(DocumentCaptureMode.importImage);
  }

  /// Le réseau vu par la séance : hors ligne, le flash dit « mise en file ».
  bool online = true;

  Future<void> setUp() async {
    cameras = FakeCameras([backLens]);
    online = true;
    await getIt.reset();
    when(
      () => _repository.loadIndex(),
    ).thenAnswer((_) async => const Right(<String, StudentPhotoRef>{}));
    when(() => files.acquire(any())).thenAnswer((_) async => null);
    _unregister = registerInertStudentPhotoModule();
    getIt
      ..registerFactory<StudentPhotoCaptureCubit>(
        () => StudentPhotoCaptureCubit(
          cameras: cameras,
          files: files,
          encoder: FakeEncoder(),
          save: SaveStudentPhotoUseCase(_repository),
        ),
      )
      ..registerFactory<PhotoSessionCubit>(sessionCubit)
      ..registerFactory<PhotoNetworkCubit>(() {
        final network = _MockNetwork();
        when(() => network.state).thenReturn(online);
        when(() => network.start()).thenAnswer((_) async {});
        return network;
      });
  }

  /// L'écriture d'une photo réussit : sans elle, Mocktail rend `null`, la
  /// prise échoue en silence et le flash n'est jamais émis.
  void acceptSaves() {
    when(
      () => _repository.savePhoto(
        studentId: any(named: 'studentId'),
        jpeg: any(named: 'jpeg'),
        takenAt: any(named: 'takenAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  }

  /// Une séance sur la classe simulée et les caméras du banc.
  PhotoSessionCubit sessionCubit() => PhotoSessionCubit(
    classes: LoadPhotoSessionClassesUseCase(
      rosters: _Rosters(),
      photos: _repository,
    ),
    save: SaveStudentPhotoUseCase(_repository),
    encoder: FakeEncoder(),
    cameras: cameras,
    files: files,
  );

  Future<void> tearDown() async {
    await _unregister();
    await getIt.reset();
  }
}

/// Pose [child] dans une fenêtre de [size] dp, texte à [textScale].
Future<void> pumpPhotoApp(
  WidgetTester tester,
  Widget child, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final year = _MockYear();
  when(() => year.state).thenReturn(const AcademicYearContextState.initial());
  await tester.pumpWidget(
    BlocProvider<AcademicYearContextBloc>.value(
      value: year,
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: child,
      ),
    ),
  );
}

/// Quelques images, sans attendre la fin des animations sans fin (sablier
/// de la caméra, squelettes).
Future<void> settleFrames(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Le bas de [finder] tient-il dans la fenêtre ?
void expectOnScreen(WidgetTester tester, Finder finder, Size window) {
  final rect = tester.getRect(finder);
  expect(rect.bottom, lessThanOrEqualTo(window.height), reason: '$window');
  expect(rect.top, greaterThanOrEqualTo(0), reason: '$window');
  expect(rect.right, lessThanOrEqualTo(window.width), reason: '$window');
}
