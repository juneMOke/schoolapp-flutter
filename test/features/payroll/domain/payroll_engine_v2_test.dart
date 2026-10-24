import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_schedule.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../payroll_builders.dart';

/// La formule v2 (état de paie des écoles), en centimes.
///
/// ⚠️ Cas écrits par la tablette d'après le contrat accepté le 2026-10-24
/// (T1-T6) : les vecteurs v2 du back les remplaceront, recopiés octet à
/// octet comme `engine-vectors.json`.
void main() {
  final usd = PayrollSettings.defaults.of('USD');

  PayrollSettings settings({
    bool absence = false,
    int days = 26,
    int ipr = 0,
    int cnss = 0,
  }) => PayrollSettings.defaults.copyWith(
    workDaysDivisor: days,
    absenceDeductionEnabled: absence,
    byCurrency: {
      'USD': PayrollCurrencySettings(
        childAllowanceInCents: usd.childAllowanceInCents,
        defaultOvertimeRateInCents: usd.defaultOvertimeRateInCents,
        overtimeRateStepInCents: usd.overtimeRateStepInCents,
        iprFlatInCents: ipr,
        cnssPermille: cnss,
      ),
    },
  );

  AttendanceSummary absences(int days) => AttendanceSummary(
    month: '2026-09',
    agents: {'m-1': AttendanceAgentSummary(unjustifiedAbsences: days)},
  );

  PayrollLine line({
    PayrollSettings? using,
    AttendanceSummary? attendance,
    PayrollVariables? variables,
    int amount = 30000,
    StaffContractKind kind = StaffContractKind.permanent,
    StaffPayMode? payMode,
    int rate = 100,
    List advances = const [],
  }) => PayrollEngine.compute(
    PayrollEngineInput(
      month: '2026-10',
      settings: using ?? settings(),
      contractsByMember: {
        'm-1': [contract('m-1', amount: amount, kind: kind, payMode: payMode)],
      },
      variables: {'m-1': ?variables},
      attendance: attendance,
      payoutRatePercent: rate,
      advances: PayrollAdvanceSchedule.statesOf(
        advances.cast(),
        '2026-10',
        const [],
      ),
    ),
  ).lines.single;

  test('réglages par défaut : le net v1, tout le net à verser', () {
    final result = line(attendance: absences(4));

    expect(result.grossInCents, 30000);
    expect(result.netInCents, 30000);
    expect(result.deductions.totalInCents, 0);
    expect(result.deductions.workedDays, 22);
    expect(result.toPayInCents, 30000);
    expect(result.deferredInCents, 0);
    expect(result.formulaVersion, 2);
  });

  test('T2 : une seule division — 300 \$, 13 jours sur 26 → 150,00 \$', () {
    final result = line(
      using: settings(absence: true),
      attendance: absences(13),
    );

    expect(result.deductions.workedDays, 13);
    expect(result.deductions.absenceInCents, 15000);
    expect(result.netInCents, 15000);
  });

  test('T1 : M−1 hors année ⇒ NJP = diviseur, rien retenu', () {
    final result = line(using: settings(absence: true));

    expect(result.deductions.workedDays, 26);
    expect(result.deductions.absenceInCents, 0);
  });

  test('NJP saisi par l économe : il prime, borné au diviseur', () {
    final over = line(
      using: settings(absence: true),
      attendance: absences(3),
      variables: const PayrollVariables(staffMemberId: 'm-1', workedDays: 40),
    );
    final typed = line(
      using: settings(absence: true),
      attendance: absences(3),
      variables: const PayrollVariables(staffMemberId: 'm-1', workedDays: 20),
    );

    expect(over.deductions.workedDays, 26);
    expect(over.deductions.absenceInCents, 0);
    expect(typed.deductions.absenceInCents, 6923); // 30000 × 6 ÷ 26
  });

  test('IPR forfaitaire et CNSS en ‰ de la base', () {
    final result = line(using: settings(ipr: 200, cnss: 35));

    expect(result.deductions.iprInCents, 200);
    expect(result.deductions.cnssInCents, 1050);
    expect(result.netInCents, 30000 - 1250);
  });

  test('T4 : la CNSS se prend sur la base avant absence', () {
    final result = line(
      using: settings(absence: true, cnss: 50),
      attendance: absences(13),
    );

    expect(result.deductions.cnssInCents, 1500);
  });

  test('T3 : bornées au brut dans l ordre, le rogné est perdu', () {
    final result = line(
      amount: 1000,
      using: settings(ipr: 200),
      variables: const PayrollVariables(
        staffMemberId: 'm-1',
        childcareInCents: 2000,
      ),
      advances: [advance('m-1', amount: 5000)],
    );

    expect(result.deductions.iprInCents, 200);
    expect(result.deductions.childcareInCents, 800);
    expect(result.netInCents, 0);
    // L'avance ne trouve plus rien : tout est reporté.
    expect(result.advances.single.carriedInCents, 5000);
  });

  test('un vacataire à l heure : ni NJP ni retenue d absence', () {
    final result = line(
      kind: StaffContractKind.vacataire,
      payMode: StaffPayMode.hourly,
      using: settings(absence: true),
      attendance: absences(5),
    );

    expect(result.deductions.workedDays, isNull);
    expect(result.deductions.absenceInCents, 0);
  });

  test('IPR seulement pour un agent payé (brut > 0)', () {
    final result = line(
      kind: StaffContractKind.vacataire,
      payMode: StaffPayMode.hourly,
      using: settings(ipr: 200),
    );

    expect(result.grossInCents, 0);
    expect(result.deductions.iprInCents, 0);
  });

  group('versement du mois', () {
    test('taux de 60 % : à verser arrondi, le reste différé', () {
      final result = line(amount: 33333, rate: 60);

      expect(result.toPayInCents, 20000);
      expect(result.deferredInCents, 13333);
      expect(result.payout!.ratePercent, 60);
    });

    test('le montant fixe prime sur le taux, borné au net', () {
      final fixed = line(
        rate: 50,
        variables: const PayrollVariables(
          staffMemberId: 'm-1',
          fixedPayoutInCents: 10000,
          fixedPayoutReason: 'Trésorerie',
        ),
      );
      final above = line(
        variables: const PayrollVariables(
          staffMemberId: 'm-1',
          fixedPayoutInCents: 99900,
        ),
      );

      expect(fixed.toPayInCents, 10000);
      expect(fixed.deferredInCents, 20000);
      expect(fixed.payout!.fixed, isTrue);
      expect(above.toPayInCents, 30000);
    });
  });

  group('empreinte v2', () {
    test('la ligne canonique porte les fixes et ce qui sera versé', () {
      final result = line(using: settings(ipr: 200), rate: 50);
      final digest = PayrollFingerprinter.digestLines([result]).single;

      expect(digest.canonical, 'm-1|USD|30000|200|0|29800|14900');
    });

    test('v1 et v2 diffèrent : un serveur v1 rendrait PAYROLL_STALE', () async {
      final lines = [line()];
      final v1 = await PayrollFingerprinter.of(lines, formulaVersion: 1);
      final v2 = await PayrollFingerprinter.of(lines);

      expect(v2.formulaVersion, 2);
      expect(v1.linesDigest, isNot(v2.linesDigest));
    });
  });
}
