import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
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
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
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

// La finalisation dispatche FinalizeDraftRequested puis affiche la popin de
// résultat (EnrollmentFinalizeOverlay, processing → succès | échec) : on
// pilote les états offline à la main via un StreamController (whenListen),
// comme pour la sur-couche d'encaissement (Finances).
class _MockOfflineBloc
    extends MockBloc<EnrollmentOfflineEvent, EnrollmentOfflineState>
    implements EnrollmentOfflineBloc {}

class _MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

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
  late _MockSyncStatusCubit syncCubit;
  late StreamController<EnrollmentOfflineState> states;

  setUp(() {
    offlineBloc = _MockOfflineBloc();
    states = StreamController<EnrollmentOfflineState>.broadcast();
    whenListen(
      offlineBloc,
      states.stream,
      initialState: const EnrollmentOfflineInitial(),
    );

    syncCubit = _MockSyncStatusCubit();
    whenListen(
      syncCubit,
      const Stream<SyncStatusState>.empty(),
      initialState: const SyncStatusState(status: SyncStatus.synced),
    );
    when(() => syncCubit.notifyLocalWrite()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await states.close();
  });

  // La finalisation passe par une popin de confirmation PUIS par la popin de
  // résultat de la sur-couche : les deux poussent une route sur le Navigator
  // racine, d'où le besoin d'un MaterialApp complet (+ délégués l10n, la
  // sur-couche affichant ses propres textes via AppLocalizations.of).
  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    // Le succès finalise en redirigeant via `context.goNamed` (GoRouter) : la
    // route racine doit exister pour que la redirection ne plante pas.
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
    await tester.pumpWidget(
      // Le cubit de synchro est fourni AU-DESSUS de MaterialApp (comme à la
      // racine en prod) pour que la popin, poussée sur le root navigator, le
      // trouve via context.read.
      BlocProvider<SyncStatusCubit>.value(
        value: syncCubit,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
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

  // Déroule la soumission jusqu'au bout : ouverture de la popin de
  // confirmation, tap sur [confirmLabel] (ou annulation), puis — si confirmée
  // — la popin de résultat (processing → succès | échec) simulée via
  // [terminalState] et fermée via [resultActionLabel].
  Future<StepSubmitResult> submitThroughDialog(
    WidgetTester tester,
    Future<StepSubmitResult> pending, {
    required String tapLabel,
    EnrollmentOfflineState? terminalState,
    String? resultActionLabel,
  }) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text(tapLabel));
    // Ferme la popin de confirmation et ouvre la popin de résultat
    // (processing) — pas de pumpAndSettle : le médaillon de traitement tourne
    // en boucle (animation infinie).
    await tester.pump();

    if (terminalState != null) {
      states.add(terminalState);
      await tester.pump(); // applique l'issue
      await tester.pump(const Duration(milliseconds: 600)); // halo/anim
      await tester.tap(find.text(resultActionLabel!));
      await tester.pump();
    }

    return pending;
  }

  testWidgets(
    'NEW → popin confirmée → finalise le brouillon local → succès → redirige',
    (tester) async {
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
        terminalState: const EnrollmentDraftFinalizedPendingSync('enr-1'),
        resultActionLabel: 'Continuer',
      );

      expect(result.status, StepSubmitStatus.completed);
      final captured = verify(() => offlineBloc.add(captureAny())).captured;
      expect(captured.single, isA<FinalizeDraftRequested>());
      expect((captured.single as FinalizeDraftRequested).enrollmentId, 'enr-1');
      verify(() => syncCubit.notifyLocalWrite()).called(1);
    },
  );

  testWidgets(
    'popin confirmée → échec de la finalisation → reste éditable (blocked)',
    (tester) async {
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
        terminalState: const EnrollmentDraftFinalizeError('boom'),
        resultActionLabel: 'Fermer',
      );

      expect(result.status, StepSubmitStatus.blocked);
      verify(() => offlineBloc.add(captureAny())).called(1);
      verifyNever(() => syncCubit.notifyLocalWrite());
    },
  );

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
        terminalState: const EnrollmentDraftFinalizedPendingSync('enr-1'),
        resultActionLabel: 'Continuer',
      );

      expect(result.status, StepSubmitStatus.completed);
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
