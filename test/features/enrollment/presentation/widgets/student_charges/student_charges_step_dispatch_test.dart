import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Aiguillage du chargement de l'étape Frais : flux BROUILLON (année connue)
/// → génération FF5 + lecture (DraftStudentChargesRequested) ; sinon lecture
/// simple (StudentChargesRequested) — y compris en dégradé année vide.
class _MockStudentChargesBloc extends Mock implements StudentChargesBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const StudentChargesRequested(studentId: 'x', levelId: 'x'),
    );
  });

  late _MockStudentChargesBloc chargesBloc;

  setUp(() {
    chargesBloc = _MockStudentChargesBloc();
    when(() => chargesBloc.state).thenReturn(const StudentChargesState());
    when(
      () => chargesBloc.stream,
    ).thenAnswer((_) => const Stream<StudentChargesState>.empty());
    when(() => chargesBloc.close()).thenAnswer((_) async {});
    getIt.registerFactory<StudentChargesBloc>(() => chargesBloc);
  });

  tearDown(() => getIt.reset());

  Future<void> pumpStep(
    WidgetTester tester, {
    required bool initializeDraftCharges,
    String academicYearId = '',
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: StudentChargesStep(
            studentId: 'stu-1',
            levelId: 'lvl-1',
            enrollmentStatus: EnrollmentStatus.inProgress,
            isEditable: false,
            showInlineSaveButton: false,
            initializeDraftCharges: initializeDraftCharges,
            academicYearId: academicYearId,
            schoolLevelGroupId: 'grp-1',
          ),
        ),
      ),
    );
  }

  testWidgets('flux brouillon + année connue → DraftStudentChargesRequested', (
    tester,
  ) async {
    await pumpStep(
      tester,
      initializeDraftCharges: true,
      academicYearId: 'ay-1',
    );

    final captured = verify(() => chargesBloc.add(captureAny())).captured;
    expect(captured, hasLength(1));
    final event = captured.single as DraftStudentChargesRequested;
    expect(event.studentId, 'stu-1');
    expect(event.levelId, 'lvl-1');
    expect(event.academicYearId, 'ay-1');
    expect(event.schoolLevelGroupId, 'grp-1');
  });

  testWidgets('année vide → dégradé en lecture simple', (tester) async {
    await pumpStep(tester, initializeDraftCharges: true);

    final captured = verify(() => chargesBloc.add(captureAny())).captured;
    expect(captured.single, isA<StudentChargesRequested>());
  });

  testWidgets('hors flux brouillon → lecture simple', (tester) async {
    await pumpStep(
      tester,
      initializeDraftCharges: false,
      academicYearId: 'ay-1',
    );

    final captured = verify(() => chargesBloc.add(captureAny())).captured;
    expect(captured.single, isA<StudentChargesRequested>());
  });
}
