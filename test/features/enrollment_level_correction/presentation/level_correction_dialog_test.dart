import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_request.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';

class _MockCubit extends MockCubit<LevelCorrectionGestureState>
    implements LevelCorrectionGestureCubit {}

const _subject = LevelCorrectionSubject(
  enrollmentId: 'enr-1',
  studentId: 'stu-1',
  academicYearId: 'year-1',
  fromSchoolLevelId: 'lvl-m2',
  fromLevelName: '2e maternelle',
);

const _levels = [
  LevelOption(
    id: 'lvl-m2',
    name: '2e maternelle',
    groupId: 'grp-mat',
    groupName: 'Maternelle',
  ),
  LevelOption(
    id: 'lvl-p2',
    name: '2e primaire',
    groupId: 'grp-prim',
    groupName: 'Primaire',
  ),
  LevelOption(
    id: 'lvl-p3',
    name: '3e primaire',
    groupId: 'grp-prim',
    groupName: 'Primaire',
  ),
];

const _inClass = LevelCorrectionClassrooms(
  currentClassroomId: 'cls-m2a',
  classrooms: [
    ClassroomOption(id: 'cls-m2a', name: 'M2 A', schoolLevelId: 'lvl-m2'),
    ClassroomOption(id: 'cls-p2a', name: 'P2 A', schoolLevelId: 'lvl-p2'),
    ClassroomOption(id: 'cls-p2b', name: 'P2 B', schoolLevelId: 'lvl-p2'),
  ],
);

void main() {
  late _MockCubit cubit;

  setUpAll(
    () => registerFallbackValue(
      const LevelCorrectionRequest(
        enrollmentId: '',
        studentId: '',
        academicYearId: '',
        fromSchoolLevelId: '',
        toSchoolLevelId: '',
        toSchoolLevelGroupId: '',
        reason: '',
      ),
    ),
  );

  setUp(() {
    cubit = _MockCubit();
    when(() => cubit.state).thenReturn(const LevelCorrectionGestureIdle());
    when(() => cubit.submit(any())).thenAnswer((_) async {});
  });

  Future<AppLocalizations> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showEteeloAdaptiveDialog<bool>(
                context: context,
                builder: (_) => BlocProvider<LevelCorrectionGestureCubit>.value(
                  value: cubit,
                  child: const LevelCorrectionDialog(
                    subject: _subject,
                    levels: _levels,
                    classrooms: _inClass,
                  ),
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(LevelCorrectionDialog)),
    )!;
  }

  Future<void> pickLevel(WidgetTester tester, String label) async {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(LevelCorrectionDialog)),
    )!;
    await tester.tap(find.text(l10n.levelCorrectionTargetLevelPlaceholder));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Finder confirm(AppLocalizations l10n) =>
      find.text(l10n.levelCorrectionConfirm).last;

  testWidgets('le niveau actuel est dit, et ne se propose pas comme cible', (
    tester,
  ) async {
    final l10n = await open(tester);
    expect(
      find.textContaining(
        l10n.levelCorrectionCurrentLevel('2e maternelle'),
        findRichText: true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.levelCorrectionTargetLevelPlaceholder));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.levelCorrectionLevelOption('Maternelle', '2e maternelle')),
      findsNothing,
    );
    expect(
      find.text(l10n.levelCorrectionLevelOption('Primaire', '2e primaire')),
      findsOneWidget,
    );
  });

  testWidgets('sans motif, le geste ne part pas', (tester) async {
    final l10n = await open(tester);
    await pickLevel(
      tester,
      l10n.levelCorrectionLevelOption('Primaire', '3e primaire'),
    );
    await tester.tap(confirm(l10n));
    await tester.pump();
    verifyNever(() => cubit.submit(any()));
  });

  testWidgets(
    'élève en classe, niveau cible avec classes : la classe est exigée (D3)',
    (tester) async {
      final l10n = await open(tester);
      await pickLevel(
        tester,
        l10n.levelCorrectionLevelOption('Primaire', '2e primaire'),
      );
      await tester.enterText(find.byType(EditableText).last, 'Erreur');
      await tester.pump();
      await tester.tap(confirm(l10n));
      await tester.pump();
      verifyNever(() => cubit.submit(any()));

      // Le motif garde le focus : on le rend avant d'ouvrir le sélecteur.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final classroomField = find.text(
        l10n.levelCorrectionTargetClassroomPlaceholder,
      );
      await tester.ensureVisible(classroomField);
      await tester.pumpAndSettle();
      await tester.tap(classroomField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('P2 B').last);
      await tester.pumpAndSettle();
      await tester.tap(confirm(l10n));
      await tester.pump();

      final request =
          verify(() => cubit.submit(captureAny())).captured.single
              as LevelCorrectionRequest;
      expect(request.toSchoolLevelId, 'lvl-p2');
      expect(request.toSchoolLevelGroupId, 'grp-prim');
      expect(request.toClassroomId, 'cls-p2b');
      expect(request.fromSchoolLevelId, 'lvl-m2');
      expect(request.reason, 'Erreur');
    },
  );

  testWidgets(
    "niveau cible sans classe : pas de classe à choisir, l'écran le dit",
    (tester) async {
      final l10n = await open(tester);
      await pickLevel(
        tester,
        l10n.levelCorrectionLevelOption('Primaire', '3e primaire'),
      );
      expect(
        find.text(l10n.levelCorrectionTargetClassroomPlaceholder),
        findsNothing,
      );
      expect(
        find.textContaining(
          l10n.levelCorrectionNoClassroomNotice,
          findRichText: true,
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(EditableText).last, 'Erreur');
      await tester.pump();
      await tester.tap(confirm(l10n));
      await tester.pump();
      final request =
          verify(() => cubit.submit(captureAny())).captured.single
              as LevelCorrectionRequest;
      expect(request.toClassroomId, isNull);
    },
  );

  testWidgets('refus local : la phrase du refus, saisie conservée', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(
      const LevelCorrectionGestureFailed(
        LevelCorrectionGestureProblem.refusedLocally,
        refusal: LevelCorrectionRefusal.hasPayments,
      ),
    );
    final l10n = await open(tester);
    expect(
      find.textContaining(
        l10n.levelCorrectionRefusedHasPayments,
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.byType(LevelCorrectionDialog), findsOneWidget);
  });

  testWidgets('geste posé : la modale se ferme', (tester) async {
    final states = StreamController<LevelCorrectionGestureState>();
    addTearDown(states.close);
    whenListen(
      cubit,
      states.stream,
      initialState: const LevelCorrectionGestureIdle(),
    );
    await open(tester);
    expect(find.byType(LevelCorrectionDialog), findsOneWidget);
    states.add(const LevelCorrectionGestureDone());
    await tester.pumpAndSettle();
    expect(find.byType(LevelCorrectionDialog), findsNothing);
  });

  testAtReferenceFormats('la modale tient sans débordement', (
    tester,
    format,
  ) async {
    final l10n = await open(tester);
    await pickLevel(
      tester,
      l10n.levelCorrectionLevelOption('Primaire', '2e primaire'),
    );
    expect(find.byType(LevelCorrectionDialog), findsOneWidget);
    expect(
      find.text(l10n.levelCorrectionTargetClassroomPlaceholder),
      findsOneWidget,
    );
  });
}
