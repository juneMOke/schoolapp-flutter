import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/target_academic_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockDraftBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockAcademicYearContextBloc extends Mock
    implements AcademicYearContextBloc {}

void main() {
  late _MockDraftBloc draftBloc;
  late _MockAcademicYearContextBloc yearBloc;
  late EnrollmentStepperFlowBloc flowBloc;

  // Cycle "Primaire" (order 1) : P1(1), P2(2). Cycle "Secondaire" (order 2) : S1(1).
  // Ids ('primaire'/'p1'...) volontairement DIFFÉRENTS des libellés N-1 (qui
  // portent d'autres ids, cf. resolver) — seul le libellé fait foi.
  final schoolLevelGroups = [
    const SchoolLevelGroupBundle(
      group: SchoolLevelGroup(
        id: 'primaire',
        name: 'Primaire',
        code: 'PRI',
        displayOrder: 1,
      ),
      levels: [
        SchoolLevel(
          id: 'p1',
          name: 'P1',
          code: 'P1',
          displayOrder: 1,
          splitIntoClassrooms: false,
        ),
        SchoolLevel(
          id: 'p2',
          name: 'P2',
          code: 'P2',
          displayOrder: 2,
          splitIntoClassrooms: false,
        ),
      ],
    ),
    const SchoolLevelGroupBundle(
      group: SchoolLevelGroup(
        id: 'secondaire',
        name: 'Secondaire',
        code: 'SEC',
        displayOrder: 2,
      ),
      levels: [
        SchoolLevel(
          id: 's1',
          name: 'S1',
          code: 'S1',
          displayOrder: 1,
          splitIntoClassrooms: false,
        ),
      ],
    ),
  ];

  const unsetTargetStudent = StudentDetail(
    id: 'stu-1',
    firstName: 'Amina',
    lastName: 'Moke',
    surname: '',
    dateOfBirth: '2015-04-02',
    gender: Gender.female,
    birthPlace: 'Kinshasa',
    nationality: '',
    city: '',
    district: '',
    municipality: '',
    neighborhood: '',
    address: '',
    schoolLevel: SchoolLevel(
      id: '',
      name: '',
      code: '',
      displayOrder: 0,
      splitIntoClassrooms: false,
    ),
    schoolLevelGroup: SchoolLevelGroup(id: '', name: '', code: ''),
  );

  // Dossier dont la classe cible a DÉJÀ été enregistrée (S1/Secondaire) —
  // pour vérifier que le calcul auto ne la retouche jamais.
  const alreadySetTargetStudent = StudentDetail(
    id: 'stu-1',
    firstName: 'Amina',
    lastName: 'Moke',
    surname: '',
    dateOfBirth: '2015-04-02',
    gender: Gender.female,
    birthPlace: 'Kinshasa',
    nationality: '',
    city: '',
    district: '',
    municipality: '',
    neighborhood: '',
    address: '',
    schoolLevel: SchoolLevel(
      id: 's1',
      name: 'S1',
      code: 'S1',
      displayOrder: 1,
      splitIntoClassrooms: false,
    ),
    schoolLevelGroup: SchoolLevelGroup(
      id: 'secondaire',
      name: 'Secondaire',
      code: 'SEC',
    ),
  );

  EnrollmentSchoolDetail buildEnrollmentDetail({
    String previousSchoolLevelLabel = '',
    String previousSchoolLevelGroupLabel = '',
    required bool validatedPreviousYear,
    // previousRank non-null = signal que l'étape Antécédents a déjà été
    // enregistrée (moyenne+rang requis pour sauvegarder) ; sans ça, le
    // calcul auto reste désactivé (cf. _hasConfirmedPreviousYearData).
    int? previousRank = 5,
    // schoolLevelId/schoolLevelGroupId PERSISTÉS : tant qu'ils sont vides, le
    // calcul auto peut s'appliquer ; dès qu'ils sont renseignés, plus jamais.
    String schoolLevelId = '',
    String schoolLevelGroupId = '',
  }) => EnrollmentSchoolDetail(
    id: 'enr-1',
    status: EnrollmentStatus.preRegistered,
    academicYearId: 'ay-2026',
    enrollmentCode: '',
    previousSchoolName: '',
    previousAcademicYear: '',
    previousSchoolLevelGroup: previousSchoolLevelGroupLabel,
    previousSchoolLevel: previousSchoolLevelLabel,
    previousRate: 0,
    previousRank: previousRank,
    validatedPreviousYear: validatedPreviousYear,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
  );

  setUpAll(() {
    registerFallbackValue(
      const SaveDraftTargetAcademicRequested(enrollmentId: 'x'),
    );
  });

  setUp(() {
    draftBloc = _MockDraftBloc();
    yearBloc = _MockAcademicYearContextBloc();
    flowBloc = EnrollmentStepperFlowBloc(
      totalSteps: 7,
      initialStepStates: const {0: StepFormState()},
    );

    when(
      () => draftBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
    when(() => draftBloc.state).thenReturn(const EnrollmentOfflineInitial());

    final yearState = AcademicYearContextState(
      status: AcademicYearContextLoadStatus.success,
      context: AcademicYearContext(
        academicYear: AcademicYear(
          id: 'ay-2026',
          name: '2026-2027',
          startDate: DateTime(2026, 9, 1),
          endDate: DateTime(2027, 7, 1),
          current: true,
        ),
        schoolLevelGroups: schoolLevelGroups,
      ),
      errorMessage: null,
    );
    when(() => yearBloc.state).thenReturn(yearState);
    when(
      () => yearBloc.stream,
    ).thenAnswer((_) => const Stream<AcademicYearContextState>.empty());
  });

  tearDown(() async {
    await flowBloc.close();
  });

  Widget buildStep(
    EnrollmentSchoolDetail detail, {
    required EnrollmentStepSubmitController controller,
    StudentDetail studentDetail = unsetTargetStudent,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<EnrollmentOfflineBloc>.value(value: draftBloc),
          BlocProvider<EnrollmentStepperFlowBloc>.value(value: flowBloc),
          BlocProvider<AcademicYearContextBloc>.value(value: yearBloc),
        ],
        child: Scaffold(
          body: SingleChildScrollView(
            child: TargetAcademicInfoStep(
              studentDetail: studentDetail,
              enrollmentDetail: detail,
              studentId: 'stu-1',
              enrollmentId: 'enr-1',
              showInlineSaveButton: false,
              flowStepIndex: 0,
              stepController: controller,
            ),
          ),
        ),
      ),
    );
  }

  SaveDraftTargetAcademicRequested captureLastSave() =>
      verify(() => draftBloc.add(captureAny())).captured.single
          as SaveDraftTargetAcademicRequested;

  testWidgets(
    'année validée → sélectionne automatiquement le niveau suivant du '
    'même cycle (matching par LABEL) et affiche le badge Auto',
    (tester) async {
      final controller = EnrollmentStepSubmitController();
      await tester.pumpWidget(
        buildStep(
          buildEnrollmentDetail(
            previousSchoolLevelLabel: 'P1',
            previousSchoolLevelGroupLabel: 'Primaire',
            validatedPreviousYear: true,
          ),
          controller: controller,
        ),
      );
      await tester.pump();
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.targetLevelAutoBadge), findsOneWidget);

      controller.submitForm();
      await tester.pump();

      final captured = captureLastSave();
      expect(captured.schoolLevelGroupId, 'primaire');
      expect(captured.schoolLevelId, 'p2');
    },
  );

  testWidgets('année NON validée → redouble (reste sur la classe précédente)', (
    tester,
  ) async {
    final controller = EnrollmentStepSubmitController();
    await tester.pumpWidget(
      buildStep(
        buildEnrollmentDetail(
          previousSchoolLevelLabel: 'P1',
          previousSchoolLevelGroupLabel: 'Primaire',
          validatedPreviousYear: false,
        ),
        controller: controller,
      ),
    );
    await tester.pump();
    await tester.pump();

    controller.submitForm();
    await tester.pump();

    final captured = captureLastSave();
    expect(captured.schoolLevelGroupId, 'primaire');
    expect(captured.schoolLevelId, 'p1');
  });

  testWidgets(
    'target encore vide en base : un changement d\'année validée dans '
    'l\'étape Antécédents (même session) fait progresser la classe cible',
    (tester) async {
      final controller = EnrollmentStepSubmitController();

      await tester.pumpWidget(
        buildStep(
          buildEnrollmentDetail(
            previousSchoolLevelLabel: 'P1',
            previousSchoolLevelGroupLabel: 'Primaire',
            validatedPreviousYear: false,
          ),
          controller: controller,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Ré-injecte le MÊME widget (même State, via le même controller lié)
      // avec validatedPreviousYear basculé à true, comme le ferait le
      // stepper après sauvegarde de l'étape Antécédents ailleurs dans le
      // wizard. Le calcul auto reprend la main tant que rien n'est encore
      // persisté pour la classe cible de CE dossier (schoolLevelId reste '').
      await tester.pumpWidget(
        buildStep(
          buildEnrollmentDetail(
            previousSchoolLevelLabel: 'P1',
            previousSchoolLevelGroupLabel: 'Primaire',
            validatedPreviousYear: true,
          ),
          controller: controller,
        ),
      );
      await tester.pump();
      await tester.pump();

      controller.submitForm();
      await tester.pump();

      final captured = captureLastSave();
      expect(captured.schoolLevelGroupId, 'primaire');
      expect(captured.schoolLevelId, 'p2');
    },
  );

  testWidgets(
    'classe cible DÉJÀ persistée (dossier repris) → jamais retouchée par '
    'le calcul auto, même avec des antécédents confirmés qui progresseraient',
    (tester) async {
      final controller = EnrollmentStepSubmitController();
      await tester.pumpWidget(
        buildStep(
          buildEnrollmentDetail(
            previousSchoolLevelLabel: 'P1',
            previousSchoolLevelGroupLabel: 'Primaire',
            validatedPreviousYear: true,
            schoolLevelId: 's1',
            schoolLevelGroupId: 'secondaire',
          ),
          controller: controller,
          studentDetail: alreadySetTargetStudent,
        ),
      );
      await tester.pump();
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.targetLevelAutoBadge), findsNothing);

      controller.submitForm();
      await tester.pump();

      // Rien à sauvegarder : la sélection n'a pas bougé par rapport au
      // snapshot initial (persisté) → le formulaire n'est pas dirty.
      verifyNever(() => draftBloc.add(any()));
    },
  );

  testWidgets(
    'pas de libellé de niveau précédent (première inscription) → défaut '
    'premier niveau du premier cycle, sans badge Auto',
    (tester) async {
      final controller = EnrollmentStepSubmitController();
      await tester.pumpWidget(
        buildStep(
          buildEnrollmentDetail(validatedPreviousYear: false),
          controller: controller,
        ),
      );
      await tester.pump();
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.targetLevelAutoBadge), findsNothing);

      controller.submitForm();
      await tester.pump();

      final captured = captureLastSave();
      expect(captured.schoolLevelGroupId, 'primaire');
      expect(captured.schoolLevelId, 'p1');
    },
  );

  testWidgets(
    'Antécédents pas encore confirmé (previousRank null) → pas de calcul '
    'auto ni de badge, même avec un libellé + validatedPreviousYear',
    (tester) async {
      final controller = EnrollmentStepSubmitController();
      await tester.pumpWidget(
        buildStep(
          buildEnrollmentDetail(
            previousSchoolLevelLabel: 'P1',
            previousSchoolLevelGroupLabel: 'Primaire',
            validatedPreviousYear: true,
            previousRank: null,
          ),
          controller: controller,
        ),
      );
      await tester.pump();
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.targetLevelAutoBadge), findsNothing);

      controller.submitForm();
      await tester.pump();

      // Défaut naïf (1er groupe/1er niveau), PAS la progression 'p2' : sans
      // confirmation de l'étape Antécédents, validatedPreviousYear=true n'est
      // pas fiable (défaut non distinguable d'une vraie saisie).
      final captured = captureLastSave();
      expect(captured.schoolLevelGroupId, 'primaire');
      expect(captured.schoolLevelId, 'p1');
    },
  );
}
