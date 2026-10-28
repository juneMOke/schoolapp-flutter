import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_payout_policy.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payslip_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_read_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_settings_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_commands.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/pages/payroll_page.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_sync_signals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

class _MockRepository extends Mock implements PayrollRepository {}

class _MockPayslips extends Mock implements PayslipRepository {}

class _MockSignals extends Mock implements StaffSyncSignals {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

const _write = [Perm.hrPayRead, Perm.hrPayWrite];
const _manage = [Perm.hrPayRead, Perm.hrPayManage];

void main() {
  late _MockRepository repository;

  setUpAll(() {
    registerFallbackValue(PayrollGestureKind.submit);
    registerFallbackValue(
      const PayrollDisbursementDraft(
        month: 'm',
        staffMemberId: 's',
        validationGestureId: 'g',
        amount: Money(0, 'USD'),
        mode: PayoutMode.cash,
      ),
    );
  });

  PayrollSnapshot snapshotOf({
    PayrollStatus? status,
    List<PayrollGesture> gestures = const [],
    Map<String, PayrollPayoutPolicy> policies = const {},
    List<PayrollDisbursement> disbursements = const [],
  }) => PayrollSnapshot(
    members: [
      member('m-1', lastName: 'Mayala', firstName: 'Ruth'),
      member('m-2', lastName: 'Kalala', firstName: 'Didier'),
    ],
    contractsByMember: {
      'm-1': [contract('m-1')],
      'm-2': [contract('m-2', amount: 22800)],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: {
      if (status != null)
        '2026-10': PayrollHeader(
          id: 'p-10',
          month: '2026-10',
          status: status,
          validationGestureId: status == PayrollStatus.validated ? 'g-v' : null,
        ),
    },
    variables: const {},
    frozenLines: {
      if (status == PayrollStatus.validated)
        '2026-10': [
          frozenLine('m-1', '2026-10'),
          frozenLine('m-2', '2026-10', gross: 22800),
        ],
    },
    summaries: const {},
    gestures: gestures,
    advances: const [],
    disbursements: disbursements,
    schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
    payoutPolicies: policies,
  );

  Future<void> pump(
    WidgetTester tester, {
    required PayrollSnapshot snapshot,
    List<Perm> permissions = _write,
    Size size = const Size(1400, 1600),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    repository = _MockRepository();
    when(() => repository.load()).thenAnswer((_) async => Right(snapshot));
    when(
      () => repository.recordGesture(
        any(),
        any(),
        reason: any(named: 'reason'),
        expected: any(named: 'expected'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.disburse(any()),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.savePayoutPolicy(
        any(),
        any(),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    final signals = _MockSignals();
    when(() => signals.watch(any())).thenReturn(() {});
    when(() => signals.pull()).thenAnswer((_) async {});
    when(() => signals.flush()).thenAnswer((_) async {});
    final cubit = PayrollCubit(
      load: LoadPayrollUseCase(repository),
      signals: signals,
      commands: PayrollCommands(
        variables: SavePayrollVariablesUseCase(repository),
        payoutPolicy: SavePayrollPayoutPolicyUseCase(repository),
        gesture: RecordPayrollGestureUseCase(repository),
        disburse: DisbursePayrollUseCase(repository),
        cancelDisbursement: CancelPayrollDisbursementUseCase(repository),
        grant: GrantSalaryAdvanceUseCase(repository),
        cancelAdvance: CancelSalaryAdvanceUseCase(repository),
        profile: SaveStaffPayProfileUseCase(repository),
        settings: SavePayrollSettingsUseCase(repository),
        share: RecordPayslipShareUseCase(repository),
        payslip: FetchPayslipUseCase(_MockPayslips()),
      ),
      now: () => DateTime(2026, 10, 26, 10),
    );
    final auth = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: [for (final p in permissions) p.wire],
    );
    when(() => auth.state).thenReturn(state);
    whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: auth,
            child: BlocProvider.value(
              value: cubit..load(),
              child: const PayrollScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('le livre d un brouillon : une ligne par agent, soumettre', (
    tester,
  ) async {
    await pump(tester, snapshot: snapshotOf());

    expect(find.text('Mayala Mutombo Ruth'), findsOneWidget);
    expect(find.text('Kalala Mutombo Didier'), findsOneWidget);

    await tester.tap(find.text('Soumettre à la direction'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Soumettre la paie'), findsOneWidget);
    await tester.tap(find.text('Soumettre à la direction').last);
    await tester.pumpAndSettle();

    final expected = verify(
      () => repository.recordGesture(
        '2026-10',
        PayrollGestureKind.submit,
        reason: null,
        expected: captureAny(named: 'expected'),
      ),
    ).captured.single;
    expect(expected, isNotNull);
  });

  testWidgets('taux du mois : l économe le fixe, motif exigé sous 100 %', (
    tester,
  ) async {
    await pump(tester, snapshot: snapshotOf());
    expect(find.text('Versement intégral du net'), findsOneWidget);

    await tester.tap(find.text('Fixer un taux de versement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 %'));
    await tester.pump();
    await tester.tap(find.text('Appliquer 60 %'));
    await tester.pump();
    verifyNever(
      () => repository.savePayoutPolicy(
        any(),
        any(),
        reason: any(named: 'reason'),
      ),
    );

    await tester.enterText(find.byType(TextField).last, 'Trésorerie tendue');
    await tester.pump();
    await tester.tap(find.text('Appliquer 60 %'));
    await tester.pumpAndSettle();

    verify(
      () => repository.savePayoutPolicy(
        '2026-10',
        60,
        reason: 'Trésorerie tendue',
      ),
    ).called(1);
  });

  testWidgets('taux du mois réglé : bandeau actif, « verser » sous le net', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot: snapshotOf(
        policies: {
          '2026-10': const PayrollPayoutPolicy(
            month: '2026-10',
            ratePercent: 60,
            reason: 'Trésorerie tendue',
          ),
        },
      ),
    );

    expect(
      find.text(
        "Ce mois, l'école verse 60 % du net · 2 agents en versement réduit",
      ),
      findsOneWidget,
    );
    expect(find.text('« Trésorerie tendue »'), findsOneWidget);
    expect(find.textContaining('verser 210'), findsOneWidget);
  });

  testWidgets('soumise : l économe attend, la direction valide ou renvoie', (
    tester,
  ) async {
    await pump(tester, snapshot: snapshotOf(status: PayrollStatus.submitted));
    expect(find.text('En attente de validation par la direction.'), findsOne);
    expect(find.text('Valider et verrouiller'), findsNothing);
  });

  testWidgets('soumise, direction : renvoyer exige un motif', (tester) async {
    await pump(
      tester,
      snapshot: snapshotOf(status: PayrollStatus.submitted),
      permissions: _manage,
    );

    await tester.tap(find.text('Renvoyer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renvoyer').last);
    await tester.pump();
    expect(find.text('Le motif est obligatoire.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Heures sup. de Ruth');
    await tester.tap(find.text('Renvoyer').last);
    await tester.pumpAndSettle();

    verify(
      () => repository.recordGesture(
        '2026-10',
        PayrollGestureKind.returnToDraft,
        reason: 'Heures sup. de Ruth',
        expected: null,
      ),
    ).called(1);
  });

  testWidgets('validée : verser en espèces exige l émargement', (tester) async {
    await pump(tester, snapshot: snapshotOf(status: PayrollStatus.validated));

    await tester.tap(find.text('Verser').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verser').last);
    await tester.pump();
    expect(find.text("Faites signer l'état d'émargement."), findsOneWidget);
    verifyNever(() => repository.disburse(any()));

    await tester.tap(find.text("L'agent a signé l'état d'émargement"));
    await tester.pump();
    await tester.tap(find.text('Verser').last);
    await tester.pumpAndSettle();

    final draft =
        verify(() => repository.disburse(captureAny())).captured.single
            as PayrollDisbursementDraft;
    expect(draft.validationGestureId, 'g-v');
    expect(draft.signedRegister, isTrue);
    expect(draft.mode, PayoutMode.cash);
  });

  testWidgets('B3 : un acompte laisse un reste, et se complète', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot: snapshotOf(
        status: PayrollStatus.validated,
        disbursements: const [
          PayrollDisbursement(
            id: 'd-1',
            month: '2026-10',
            staffMemberId: 'm-1',
            validationGestureId: 'g-v',
            amount: Money(10000, 'USD'),
            mode: PayoutMode.cash,
            paidAt: '2026-10-28T09:00:00.000Z',
            signedRegister: true,
          ),
        ],
      ),
    );

    await tester.tap(find.textContaining('Partiel · reste'));
    await tester.pumpAndSettle();
    expect(find.text('Déjà versé'), findsOneWidget);
    expect(find.text('n° 1'), findsOneWidget);
    final signed = find.text("L'agent a signé l'état d'émargement");
    await tester.ensureVisible(signed);
    await tester.pumpAndSettle();
    await tester.tap(signed);
    await tester.pump();
    await tester.tap(find.text('Verser').last);
    await tester.pumpAndSettle();

    final draft =
        verify(() => repository.disburse(captureAny())).captured.single
            as PayrollDisbursementDraft;
    // Prérempli au reste : 350 − 100.
    expect(draft.amount, const Money(25000, 'USD'));
    expect(draft.netInCents, 35000);
  });

  testWidgets('un refus PAYROLL_STALE s affiche avec sa comparaison', (
    tester,
  ) async {
    await pump(
      tester,
      snapshot: snapshotOf(
        status: PayrollStatus.submitted,
        gestures: [
          const PayrollGesture(
            id: 'g-1',
            month: '2026-10',
            kind: PayrollGestureKind.validate,
            recordedAt: '2026-10-26T10:00:00Z',
            syncState: RecordSyncState.failed,
            syncErrorCode: PayrollGesture.staleCode,
          ),
        ],
      ),
      permissions: _manage,
    );

    expect(find.text('Comparer'), findsOneWidget);
    await tester.tap(find.text('Comparer'));
    await tester.pumpAndSettle();
    expect(find.text("Le serveur a trouvé d'autres chiffres"), findsOneWidget);
    expect(find.text('Synchroniser puis revoir'), findsOneWidget);
  });

  testWidgets('validée : diffuser ouvre le recueil et un WhatsApp par agent', (
    tester,
  ) async {
    await pump(tester, snapshot: snapshotOf(status: PayrollStatus.validated));

    expect(find.text('Imprimer l\'état de paie'), findsOneWidget);
    await tester.tap(find.text('Diffuser les bulletins'));
    await tester.pumpAndSettle();

    expect(find.text('Tous les bulletins (PDF)'), findsOneWidget);
    expect(find.text('Envoyer par WhatsApp'), findsNWidgets(2));
    expect(find.text('Aucun numéro pour cet agent.'), findsNWidgets(2));
  });

  for (final size in const [Size(800, 1280), Size(420, 1800)]) {
    testWidgets('aucun débordement en ${size.width.toInt()} dp', (
      tester,
    ) async {
      await pump(
        tester,
        snapshot: snapshotOf(status: PayrollStatus.validated),
        permissions: [..._write, Perm.hrPayManage],
        size: size,
      );
      await tester.tap(find.text('Diffuser les bulletins'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
