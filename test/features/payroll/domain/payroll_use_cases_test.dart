import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
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

  PayrollSnapshot snapshot({Map<String, PayrollHeader> headers = const {}}) =>
      PayrollSnapshot(
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
        disbursements: const [],
        schoolYears: const [(start: '2026-09-07', end: '2027-07-02')],
        shareTraces: const {},
        hasEverSynced: true,
      );

  PayrollMonthView view(PayrollStatus status) => PayrollLedger.monthView(
    snapshot(
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

    test('le montant est le net figé, jamais une saisie', () {
      expect(
        DisbursePayrollUseCase.refusalOf(
          view(PayrollStatus.validated),
          draft(amount: 27000),
        ),
        PayrollRule.invalidAmount,
      );
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
