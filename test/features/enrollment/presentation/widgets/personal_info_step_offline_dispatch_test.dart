import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info_step.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockStudentBloc extends Mock implements StudentBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockDraftBloc extends Mock implements EnrollmentOfflineBloc {}

class _FakePolicy extends EnrollmentDetailPolicy {
  const _FakePolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  bool isStepEditable(EnrollmentWizardStep step) => true;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}
}

/// Policy éditable dont le brouillon est de type RE (comme la réinscription) :
/// vérifie que l'étape Identité dispatche le type/statut de la POLICY.
class _FakeRePolicy extends _FakePolicy {
  const _FakeRePolicy();

  @override
  String get draftEnrollmentType => 'RE_ENROLLMENT';

  @override
  String get draftStatus => 'PRE_REGISTERED';
}

void main() {
  late _MockStudentBloc studentBloc;
  late _MockEnrollmentBloc enrollmentBloc;
  late _MockDraftBloc draftBloc;
  late EnrollmentStepperFlowBloc flowBloc;

  const prefilled = StudentDetail(
    id: 'stu-1',
    firstName: 'John',
    lastName: 'Doe',
    surname: 'Junior',
    dateOfBirth: '2015-03-02',
    gender: Gender.male,
    birthPlace: 'Abidjan',
    nationality: 'ivoirienne',
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

  setUpAll(() {
    registerFallbackValue(const EnrollmentSummariesRefreshRequested());
    registerFallbackValue(const StartDraftRequested());
  });

  setUp(() {
    studentBloc = _MockStudentBloc();
    enrollmentBloc = _MockEnrollmentBloc();
    draftBloc = _MockDraftBloc();
    flowBloc = EnrollmentStepperFlowBloc(
      totalSteps: 7,
      initialStepStates: const {0: StepFormState()},
    );

    when(
      () => studentBloc.stream,
    ).thenAnswer((_) => const Stream<StudentState>.empty());
    when(() => studentBloc.state).thenReturn(const StudentState.initial());
    when(() => studentBloc.close()).thenAnswer((_) async {});

    when(
      () => enrollmentBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentState>.empty());
    when(
      () => enrollmentBloc.state,
    ).thenReturn(const EnrollmentState.initial());

    when(
      () => draftBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
    when(() => draftBloc.state).thenReturn(const EnrollmentOfflineInitial());

    getIt.registerFactory<StudentBloc>(() => studentBloc);
  });

  tearDown(() async {
    await flowBloc.close();
    await getIt.reset();
  });

  Future<SaveDraftIdentityRequested> pumpAndSave(
    WidgetTester tester, {
    required EnrollmentDetailPolicy policy,
    required EnrollmentDetailIntent intent,
  }) async {
    final controller = EnrollmentStepSubmitController();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<EnrollmentBloc>.value(value: enrollmentBloc),
            BlocProvider<EnrollmentOfflineBloc>.value(value: draftBloc),
            BlocProvider<EnrollmentStepperFlowBloc>.value(value: flowBloc),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: PersonalInfoStep(
                studentDetail: prefilled,
                enrollmentId: 'enr-1',
                academicYearId: 'ay-1',
                flowStepIndex: 0,
                detailIntent: intent,
                detailPolicy: policy,
                stepController: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Rend le formulaire dirty (valide au chargement grâce aux champs pré-remplis).
    final firstNameField = find.byWidgetPredicate(
      (w) => w is EditableText && w.controller.text == 'John',
    );
    expect(firstNameField, findsOneWidget);
    await tester.enterText(firstNameField, 'Johnny');
    await tester.pump();

    controller.submitForm();
    await tester.pump();

    final captured = verify(() => draftBloc.add(captureAny())).captured;
    expect(captured, hasLength(1));
    expect(captured.single, isA<SaveDraftIdentityRequested>());
    return captured.single as SaveDraftIdentityRequested;
  }

  testWidgets(
    'NEW : la sauvegarde de l\'étape Identité dispatche SaveDraftIdentityRequested',
    (tester) async {
      final identity = await pumpAndSave(
        tester,
        policy: const _FakePolicy(),
        intent: const EnrollmentDetailIntent.newFirstRegistration()
            .withEnrollmentId('enr-1'),
      );

      expect(identity.enrollmentId, 'enr-1');
      expect(identity.studentId, 'stu-1');
      expect(identity.firstName, 'Johnny');
      expect(identity.academicYearId, 'ay-1');
      expect(identity.enrollmentType, 'NEW_ENROLLMENT');
      expect(identity.status, 'IN_PROGRESS');
      expect(identity.gender, 'MALE');

      // Aucun dispatch de création serveur (parcours online neutralisé).
      verifyNever(() => enrollmentBloc.add(any()));
    },
  );

  testWidgets(
    'RE : le re-save d\'identité porte le type/statut de la POLICY '
    '(pas NEW_ENROLLMENT/IN_PROGRESS) — ne requalifie pas le brouillon seedé',
    (tester) async {
      final identity = await pumpAndSave(
        tester,
        policy: const _FakeRePolicy(),
        intent: const EnrollmentDetailIntent.reRegistration(
          enrollmentId: 'enr-1',
          studentId: 'stu-1',
        ),
      );

      expect(identity.enrollmentType, 'RE_ENROLLMENT');
      expect(identity.status, 'PRE_REGISTERED');
    },
  );

  // ── Défaut « Kinshasa » du lieu de naissance ───────────────────────────────

  const blankBirthPlace = StudentDetail(
    id: 'stu-2',
    firstName: '',
    lastName: '',
    surname: '',
    dateOfBirth: '',
    gender: Gender.male,
    birthPlace: '',
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

  Future<void> pumpStep(
    WidgetTester tester, {
    required StudentDetail student,
    required bool isEditable,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<EnrollmentBloc>.value(value: enrollmentBloc),
            BlocProvider<EnrollmentOfflineBloc>.value(value: draftBloc),
            BlocProvider<EnrollmentStepperFlowBloc>.value(value: flowBloc),
          ],
          child: Scaffold(
            body: SingleChildScrollView(
              child: PersonalInfoStep(
                studentDetail: student,
                enrollmentId: 'enr-1',
                academicYearId: 'ay-1',
                flowStepIndex: 0,
                isEditable: isEditable,
                detailIntent:
                    const EnrollmentDetailIntent.newFirstRegistration()
                        .withEnrollmentId('enr-1'),
                detailPolicy: const _FakePolicy(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder birthPlaceEditable(String text) => find.byWidgetPredicate(
    (w) => w is EditableText && w.controller.text == text,
  );

  testWidgets(
    'lieu de naissance vide + formulaire éditable → défaut « Kinshasa »',
    (tester) async {
      await pumpStep(tester, student: blankBirthPlace, isEditable: true);
      expect(birthPlaceEditable('Kinshasa'), findsOneWidget);
    },
  );

  testWidgets('lieu de naissance déjà saisi → jamais écrasé par le défaut', (
    tester,
  ) async {
    await pumpStep(tester, student: prefilled, isEditable: true);
    expect(birthPlaceEditable('Abidjan'), findsOneWidget);
    expect(birthPlaceEditable('Kinshasa'), findsNothing);
  });

  testWidgets(
    'consultation lecture seule → pas de défaut (valeur fidèle au dossier)',
    (tester) async {
      await pumpStep(tester, student: blankBirthPlace, isEditable: false);
      expect(birthPlaceEditable('Kinshasa'), findsNothing);
    },
  );
}
