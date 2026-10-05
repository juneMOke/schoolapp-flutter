import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/domain/repositories/student_photo_repository.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_class_picker.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../student_photo_fakes.dart';

class _MockRepository extends Mock implements StudentPhotoRepository {}

class _MockFiles extends Mock implements DocumentCaptureGateway {}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1280, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  late StudentPhotoCaptureCubit cubit;

  setUp(() {
    cubit = StudentPhotoCaptureCubit(
      cameras: FakeCameras(const []),
      files: _MockFiles(),
      encoder: FakeEncoder(),
      save: SaveStudentPhotoUseCase(_MockRepository()),
    );
  });
  tearDown(() => cubit.close());

  group('le corps de la modale', () {
    testWidgets('caméra refusée : la carte propose l\'import', (tester) async {
      await _pump(
        tester,
        CaptureBody(
          state: const CaptureBlocked(CameraBlockReason.denied),
          cubit: cubit,
        ),
      );
      expect(find.text('Caméra bloquée'), findsOneWidget);
      expect(find.text('Importer une photo'), findsOneWidget);
    });

    testWidgets('aucune caméra : un autre titre, la même issue', (
      tester,
    ) async {
      await _pump(
        tester,
        CaptureBody(
          state: const CaptureBlocked(CameraBlockReason.none),
          cubit: cubit,
        ),
      );
      expect(find.text('Aucune caméra détectée'), findsOneWidget);
    });

    testWidgets('fichier illisible', (tester) async {
      await _pump(
        tester,
        CaptureBody(state: const CaptureBadFile(), cubit: cubit),
      );
      expect(find.text('Fichier non pris en charge'), findsOneWidget);
    });

    testWidgets('en direct : le déclencheur est actif, la bascule absente '
        'avec une seule caméra', (tester) async {
      const lens = CameraLens(name: 'back', facing: CameraFacing.back);
      await _pump(
        tester,
        CaptureBody(
          state: CaptureLive(session: FakeSession(lens), canSwitch: false),
          cubit: cubit,
        ),
      );
      expect(find.bySemanticsLabel('Prendre la photo'), findsOneWidget);
      expect(find.text('Changer de caméra'), findsNothing);
    });

    testWidgets('enregistrée : le message dit ce qui change', (tester) async {
      await _pump(
        tester,
        CaptureBody(state: CaptureSaved(Uint8List.fromList([1])), cubit: cubit),
      );
      expect(find.text('Photo enregistrée'), findsOneWidget);
    });
  });

  group('le choix de la classe', () {
    const students = [
      SessionStudent(id: 'a', lastName: 'Amani', firstName: 'Rose'),
      SessionStudent(id: 'b', lastName: 'Bola', firstName: 'Jean'),
    ];
    SessionSetup setup({String? selected, bool onlyMissing = true}) =>
        SessionSetup(
          selectedId: selected,
          onlyMissing: onlyMissing,
          classes: const [
            SessionClassSummary(
              klass: SessionClass(id: 'c', name: '6e A'),
              students: students,
              withPhoto: {'a'},
            ),
            SessionClassSummary(
              klass: SessionClass(id: 'd', name: '5e B'),
              students: students,
              withPhoto: {'a', 'b'},
            ),
          ],
        );

    Widget picker(SessionSetup state, {VoidCallback? onStart}) =>
        SessionClassPicker(
          state: state,
          onSelect: (_) {},
          onOnlyMissing: (_) {},
          onStart: onStart ?? () {},
        );

    testWidgets(
      'chaque tuile dit ce qui manque ; rien ne démarre sans classe',
      (tester) async {
        await _pump(tester, picker(setup()));
        expect(
          find.textContaining('1 sans photo', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Classe complète · 2 élèves'), findsOneWidget);
        expect(find.text('Choisissez une classe'), findsOneWidget);
      },
    );

    testWidgets('classe choisie : « Commencer · N élèves »', (tester) async {
      var started = false;
      await _pump(
        tester,
        picker(setup(selected: 'c'), onStart: () => started = true),
      );
      await tester.tap(find.text('Commencer · 1 élève'));
      expect(started, isTrue);
    });

    testWidgets('classe complète avec le filtre : l\'état vide propose de '
        'tout inclure', (tester) async {
      await _pump(tester, picker(setup(selected: 'd')));
      expect(find.text('Toute la classe a sa photo'), findsOneWidget);
      expect(find.text('Inclure toute la classe'), findsOneWidget);
    });
  });
}
