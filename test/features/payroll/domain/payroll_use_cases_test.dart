import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';

import '../../staff/staff_builders.dart';
import '../payroll_builders.dart';

class _MockRepository extends Mock implements PayrollRepository {}

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

  setUp(() {
    repository = _MockRepository();
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
  });

  PayrollSnapshot snapshot({
    Map<String, PayrollHeader> headers = const {},
    List<PayrollDisbursement> disbursements = const [],
  }) => PayrollSnapshot(
    members: [member('m-1')],
    contractsByMember: {
      'm-1': [contract('m-1')],
    },
    settings: PayrollSettings.defaults,
    profiles: const {},
    headers: headers,
    variables: const {},
    frozenLines: {
      if (headers['2026-10']?.status == PayrollStatus.validated)
        '2026-10': [frozenLine('m-1', '2026-10', gross: 27500)],
    },
    summaries: const {},
    gestures: const [],
    advances: const [],
    disbursements: disbursements,
    schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
    shareTraces: const {},
    hasEverSynced: true,
  );

  PayrollMonthView view(
    PayrollStatus status, {
    List<PayrollDisbursement> disbursements = const [],
  }) => PayrollLedger.monthView(
    snapshot(
      disbursements: disbursements,
      headers: {
        '2026-10': PayrollHeader(
          id: 'p',
          month: '2026-10',
          status: status,
          validationGestureId: status == PayrollStatus.validated ? 'g-v' : null,
        ),
      },
    ),
    '2026-10',
  );

  PayrollRule? ruleOf(Either<Failure, Unit> result) => result.fold(
    (failure) => failure is PayrollRuleFailure ? failure.rule : null,
    (_) => null,
  );

  group('v2 : variables et taux du mois', () {
    setUp(() {
      when(
        () => repository.saveVariables(any(), any()),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => repository.savePayoutPolicy(
          any(),
          any(),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => const Right(unit));
    });

    setUpAll(
      () => registerFallbackValue(const PayrollVariables(staffMemberId: 's')),
    );

    test('NJP au-delà du diviseur : refusé avant la file', () async {
      final result = await SavePayrollVariablesUseCase(repository)(
        view(PayrollStatus.draft),
        const PayrollVariables(staffMemberId: 'm-1', workedDays: 27),
      );

      expect(ruleOf(result), PayrollRule.workedDaysOutOfRange);
      verifyNever(() => repository.saveVariables(any(), any()));
    });

    test('un montant fixe sans motif est refusé', () async {
      final result = await SavePayrollVariablesUseCase(repository)(
        view(PayrollStatus.draft),
        const PayrollVariables(
          staffMemberId: 'm-1',
          fixedPayoutInCents: 10000,
          fixedPayoutReason: ' x ',
        ),
      );

      expect(ruleOf(result), PayrollRule.reasonRequired);
    });

    test('NJP dans les bornes : part', () async {
      final result = await SavePayrollVariablesUseCase(repository)(
        view(PayrollStatus.draft),
        const PayrollVariables(staffMemberId: 'm-1', workedDays: 20),
      );

      expect(result.isRight(), isTrue);
    });

    test('taux sous 100 % sans motif : refusé ; avec motif : part', () async {
      final useCase = SavePayrollPayoutPolicyUseCase(repository);

      expect(
        ruleOf(await useCase(view(PayrollStatus.draft), 60)),
        PayrollRule.reasonRequired,
      );
      expect(
        (await useCase(
          view(PayrollStatus.draft),
          60,
          reason: 'Trésorerie',
        )).isRight(),
        isTrue,
      );
      expect(
        ruleOf(await useCase(view(PayrollStatus.draft), 120)),
        PayrollRule.invalidAmount,
      );
    });

    test('taux du mois sur une paie soumise : non modifiable', () async {
      final result = await SavePayrollPayoutPolicyUseCase(repository)(
        view(PayrollStatus.submitted),
        100,
      );

      expect(ruleOf(result), PayrollRule.notEditable);
    });
  });

  group('geste du circuit', () {
    test('soumettre part avec l empreinte du livre affiché', () async {
      final result = await RecordPayrollGestureUseCase(repository)(
        view(PayrollStatus.draft),
        PayrollGestureKind.submit,
      );

      expect(result.isRight(), isTrue);
      final captured =
          verify(
                () => repository.recordGesture(
                  '2026-10',
                  PayrollGestureKind.submit,
                  reason: null,
                  expected: captureAny(named: 'expected'),
                ),
              ).captured.single
              as PayrollFingerprint;
      expect(captured.lineCount, 1);
      expect(captured.linesDigest, hasLength(64));
    });

    test('renvoyer sans motif est refusé avant la file', () async {
      final result = await RecordPayrollGestureUseCase(repository)(
        view(PayrollStatus.submitted),
        PayrollGestureKind.returnToDraft,
        reason: '  ',
      );

      expect(
        result.fold((f) => (f as PayrollRuleFailure).rule, (_) => null),
        PayrollRule.reasonRequired,
      );
    });

    test('valider un brouillon : mauvais état', () {
      expect(
        RecordPayrollGestureUseCase.refusalOf(
          view(PayrollStatus.draft),
          PayrollGestureKind.validate,
        ),
        PayrollRule.wrongPhase,
      );
    });

    test('valider avec M−1 ouvert : pointage à clore', () {
      expect(
        RecordPayrollGestureUseCase.refusalOf(
          view(PayrollStatus.submitted),
          PayrollGestureKind.validate,
        ),
        PayrollRule.attendanceOpen,
      );
    });
  });

  group('versement', () {
    PayrollDisbursementDraft draft({
      PayoutMode mode = PayoutMode.cash,
      int amount = 27500,
      bool signed = true,
      String? phone,
      String? reference,
    }) => PayrollDisbursementDraft(
      month: '2026-10',
      staffMemberId: 'm-1',
      validationGestureId: 'g-v',
      amount: Money(amount, 'USD'),
      mode: mode,
      operator: MobileMoneyOperator.mpesa,
      payoutPhone: phone,
      reference: reference,
      signedRegister: signed,
    );

    test('espèces sans émargement : refusé', () {
      expect(
        DisbursePayrollUseCase.refusalOf(
          view(PayrollStatus.validated),
          draft(signed: false),
        ),
        PayrollRule.signatureRequired,
      );
    });

    test('B3 : un acompte passe, zéro et au-delà du reste non', () {
      final validated = view(PayrollStatus.validated);

      expect(
        DisbursePayrollUseCase.refusalOf(validated, draft(amount: 10000)),
        isNull,
      );
      expect(
        DisbursePayrollUseCase.refusalOf(validated, draft(amount: 0)),
        PayrollRule.invalidAmount,
      );
      expect(
        DisbursePayrollUseCase.refusalOf(validated, draft(amount: 27501)),
        PayrollRule.exceedsBalance,
      );
    });

    test('B3 : le reste tient compte des versements déjà posés', () {
      PayrollDisbursement paid(String id, int amount) => PayrollDisbursement(
        id: id,
        month: '2026-10',
        staffMemberId: 'm-1',
        validationGestureId: 'g-v',
        amount: Money(amount, 'USD'),
        mode: PayoutMode.cash,
        paidAt: '2026-10-28T09:00:00.000Z',
        signedRegister: true,
      );
      final partly = view(
        PayrollStatus.validated,
        disbursements: [paid('d-1', 20000)],
      );
      final settled = view(
        PayrollStatus.validated,
        disbursements: [paid('d-1', 20000), paid('d-2', 7500)],
      );

      expect(
        DisbursePayrollUseCase.refusalOf(partly, draft(amount: 7500)),
        isNull,
      );
      expect(
        DisbursePayrollUseCase.refusalOf(partly, draft(amount: 7600)),
        PayrollRule.exceedsBalance,
      );
      expect(
        DisbursePayrollUseCase.refusalOf(settled, draft(amount: 100)),
        PayrollRule.alreadyDisbursed,
      );
      expect(partly.paidCount, 0);
      expect(settled.paidCount, 1);
    });

    test('mobile money : numéro E.164 et référence de 6 caractères', () {
      final validated = view(PayrollStatus.validated);
      expect(
        DisbursePayrollUseCase.refusalOf(
          validated,
          draft(mode: PayoutMode.mobileMoney, phone: '+24381234'),
        ),
        PayrollRule.mobileDetailsRequired,
      );
      expect(
        DisbursePayrollUseCase.refusalOf(
          validated,
          draft(
            mode: PayoutMode.mobileMoney,
            phone: '+243812345678',
            reference: 'TX1',
          ),
        ),
        PayrollRule.invalidReference,
      );
      expect(
        DisbursePayrollUseCase.refusalOf(
          validated,
          draft(
            mode: PayoutMode.mobileMoney,
            phone: '+243812345678',
            reference: 'TX48213377',
          ),
        ),
        isNull,
      );
    });

    test('une paie non validée ne se verse pas', () {
      expect(
        DisbursePayrollUseCase.refusalOf(
          view(PayrollStatus.submitted),
          draft(),
        ),
        PayrollRule.notValidated,
      );
    });
  });
}
