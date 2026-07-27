import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/summary_step_handler.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockOfflineBloc extends Mock implements EnrollmentOfflineBloc {}

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockFlowBloc extends Mock implements EnrollmentStepperFlowBloc {}

class _MockL10n extends Mock implements AppLocalizations {}

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

void main() {
  setUpAll(() {
    registerFallbackValue(const FinalizeDraftRequested('fallback'));
  });

  late _MockOfflineBloc offlineBloc;

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    when(() => offlineBloc.state).thenReturn(const EnrollmentOfflineInitial());
    when(
      () => offlineBloc.stream,
    ).thenAnswer((_) => const Stream<EnrollmentOfflineState>.empty());
  });

  // La finalisation passe désormais par une popin de confirmation : le contexte
  // doit porter un Navigator (MaterialApp) pour que showDialog fonctionne.
  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<EnrollmentOfflineBloc>.value(
          value: offlineBloc,
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  _MockL10n buildL10n() {
    final l10n = _MockL10n();
    when(() => l10n.enrollmentFinalizeConfirmTitle).thenReturn('Valider ?');
    when(
      () => l10n.enrollmentFinalizeConfirmMessage,
    ).thenReturn('Confirmer le dossier ?');
    when(() => l10n.validateEnrollment).thenReturn('Valider l\'inscription');
    when(() => l10n.cancel).thenReturn('Annuler');
    return l10n;
  }

  HandlerSubmitContext buildSubmitContext(
    BuildContext context,
    EnrollmentDetailIntent intent,
  ) {
    return HandlerSubmitContext(
      context: context,
      enrollmentBloc: _MockEnrollmentBloc(),
      flowBloc: _MockFlowBloc(),
      enrollmentState: const EnrollmentState.initial(),
      detail: _buildDetail(),
      intent: intent,
      detailPolicy: const _FakePolicy(),
      l10n: buildL10n(),
    );
  }

  // Déroule la soumission jusqu'au bout : ouverture de la popin, tap sur le
  // bouton [confirmLabel] (ou annulation), puis résultat du handler.
  Future<StepSubmitResult> submitThroughDialog(
    WidgetTester tester,
    Future<StepSubmitResult> pending, {
    required String tapLabel,
  }) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text(tapLabel));
    await tester.pumpAndSettle();
    return pending;
  }

  testWidgets('NEW → popin confirmée → finalise le brouillon local', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final handler = SummaryStepHandler();

    final pending = handler.submit(
      buildSubmitContext(
        context,
        const EnrollmentDetailIntent.newFirstRegistration().withEnrollmentId(
          'enr-1',
        ),
      ),
    );
    final result = await submitThroughDialog(
      tester,
      pending,
      tapLabel: 'Valider l\'inscription',
    );

    expect(result.status, StepSubmitStatus.dispatched);
    final captured = verify(() => offlineBloc.add(captureAny())).captured;
    expect(captured.single, isA<FinalizeDraftRequested>());
    expect((captured.single as FinalizeDraftRequested).enrollmentId, 'enr-1');
  });

  testWidgets('popin refusée → aucune finalisation (noop)', (tester) async {
    final context = await pumpContext(tester);
    final handler = SummaryStepHandler();

    final pending = handler.submit(
      buildSubmitContext(
        context,
        const EnrollmentDetailIntent.newFirstRegistration().withEnrollmentId(
          'enr-1',
        ),
      ),
    );
    final result = await submitThroughDialog(
      tester,
      pending,
      tapLabel: 'Annuler',
    );

    expect(result.status, StepSubmitStatus.noop);
    verifyNever(() => offlineBloc.add(any()));
  });

  testWidgets(
    'RE → MÊME chemin : popin confirmée → finalise le brouillon local',
    (tester) async {
      final context = await pumpContext(tester);
      final handler = SummaryStepHandler();

      final pending = handler.submit(
        buildSubmitContext(
          context,
          const EnrollmentDetailIntent.reRegistration(
            enrollmentId: 'enr-2',
            studentId: 'stu-2',
          ),
        ),
      );
      final result = await submitThroughDialog(
        tester,
        pending,
        tapLabel: 'Valider l\'inscription',
      );

      expect(result.status, StepSubmitStatus.dispatched);
      final captured = verify(() => offlineBloc.add(captureAny())).captured;
      expect(captured.single, isA<FinalizeDraftRequested>());
      expect((captured.single as FinalizeDraftRequested).enrollmentId, 'enr-1');
    },
  );

  testWidgets('écriture de brouillon en cours → soumission bloquée', (
    tester,
  ) async {
    when(() => offlineBloc.state).thenReturn(const EnrollmentDraftSaving());
    final context = await pumpContext(tester);
    final handler = SummaryStepHandler();

    final result = await handler.submit(
      buildSubmitContext(
        context,
        const EnrollmentDetailIntent.newFirstRegistration().withEnrollmentId(
          'enr-1',
        ),
      ),
    );

    expect(result.status, StepSubmitStatus.blocked);
    verifyNever(() => offlineBloc.add(any()));
  });

  testWidgets('consultation lecture seule (dossier LOCAL non synchronisé) → '
      'retour/redirect, JAMAIS de finalisation', (tester) async {
    // Garde read-only : un dossier ouvert en consultation
    // (isReadOnlyConsultation == true, ici via LocalConsultationDetailPolicy)
    // ne doit JAMAIS re-finaliser — sinon un PENDING_SYNC déjà en file de
    // synchro serait re-poussé. On monte un GoRouter minimal (le redirect
    // fait un goNamed) + un ScaffoldMessenger (le toast d'info) pour laisser
    // la branche s'exécuter jusqu'au bout. Tue le mutant qui retirerait la
    // disjonction `|| context.detailPolicy.isReadOnlyConsultation`.
    final l10n = _MockL10n();
    when(() => l10n.completedEnrollmentRedirecting).thenReturn('redirection…');

    late BuildContext captured;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: AppRoutesNames.home,
          builder: (context, state) =>
              BlocProvider<EnrollmentOfflineBloc>.value(
                value: offlineBloc,
                child: Builder(
                  builder: (context) {
                    captured = context;
                    return const Scaffold(body: SizedBox.shrink());
                  },
                ),
              ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final handler = SummaryStepHandler();
    final result = await handler.submit(
      HandlerSubmitContext(
        context: captured,
        enrollmentBloc: _MockEnrollmentBloc(),
        flowBloc: _MockFlowBloc(),
        enrollmentState: const EnrollmentState.initial(),
        detail: _buildDetail(),
        intent: const EnrollmentDetailIntent.newFirstRegistration()
            .withEnrollmentId('enr-1'),
        detailPolicy: const LocalConsultationDetailPolicy(),
        l10n: l10n,
      ),
    );

    expect(result.status, StepSubmitStatus.completed);
    verifyNever(() => offlineBloc.add(any()));

    // Vide la frame de navigation + le timer d'auto-fermeture du SnackBar.
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
  });
}

EnrollmentDetail _buildDetail() {
  return EnrollmentDetail(
    studentDetail: const StudentDetail(
      id: 'stu-1',
      firstName: 'John',
      lastName: 'Doe',
      surname: 'Junior',
      dateOfBirth: '2010-01-01',
      gender: Gender.male,
      birthPlace: 'Abidjan',
      nationality: 'ivoirienne',
      city: 'Abidjan',
      district: 'Cocody',
      municipality: 'Riviera',
      neighborhood: 'Riviera 2',
      address: 'lot 10',
      schoolLevel: SchoolLevel(
        id: 'level-1',
        name: '6eme',
        code: '6E',
        displayOrder: 1,
        splitIntoClassrooms: false,
      ),
      schoolLevelGroup: SchoolLevelGroup(
        id: 'group-1',
        name: 'College',
        code: 'COL',
      ),
    ),
    parentDetails: const <ParentSummary>[
      ParentSummary(
        id: 'parent-1',
        firstName: 'Jane',
        lastName: 'Doe',
        identificationNumber: 'ID-1',
        phoneNumber: '+22501020304',
        email: 'jane.doe@example.com',
        relationshipType: RelationshipType.mother,
      ),
    ],
    enrollmentDetail: const EnrollmentSchoolDetail(
      id: 'enr-1',
      status: EnrollmentStatus.inProgress,
      academicYearId: 'ay-1',
      enrollmentCode: 'ENR-1',
      previousSchoolName: 'School',
      previousAcademicYear: '2024-2025',
      previousSchoolLevelGroup: 'College',
      previousSchoolLevel: '5eme',
      previousRate: 12.0,
      previousRank: 5,
      validatedPreviousYear: true,
      schoolLevelGroupId: 'group-1',
      schoolLevelId: 'level-1',
    ),
  );
}
