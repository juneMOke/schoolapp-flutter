import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';

/// Les retenues fixes et le versement du mois (formule v2) : des fonctions
/// pures, en centimes, une seule division par montant (T2).
///
/// ```text
/// NJP      variable ?? diviseur − absences NJ du Pointage M−1    [0, diviseur]
///          M−1 hors année : diviseur (T1) · vacataire à l'heure : sans objet
/// absence  réglage actif ? roundDiv(base × (diviseur − NJP), diviseur) : 0
/// IPR      brut > 0 ? forfait[devise] : 0
/// CNSS     roundDiv(base × ‰[devise], 1000)        (base avant absence, T4)
/// PC/E     variable ?? 0
/// ```
/// Pris sur le brut dans cet ordre, chacun borné à ce qui reste (T3).
abstract final class PayrollDeductions {
  static PayrollLineDeductions compute({
    required bool hourly,
    required int baseInCents,
    required int grossInCents,
    required PayrollSettings settings,
    required PayrollCurrencySettings perCurrency,
    required PayrollVariables? variables,
    required AttendanceAgentSummary? attendance,
  }) {
    final divisor = settings.workDaysDivisor;
    final worked = hourly
        ? null
        : workedDaysOf(
            divisor: divisor,
            variable: variables?.workedDays,
            attendance: attendance,
          );
    var capacity = grossInCents;
    int take(int amount) {
      final taken = amount < capacity ? amount : capacity;
      capacity -= taken;
      return taken;
    }

    final absence = take(
      worked != null && settings.absenceDeductionEnabled && divisor > 0
          ? PayrollMath.roundDiv(baseInCents * (divisor - worked), divisor)
          : 0,
    );
    final ipr = take(grossInCents > 0 ? perCurrency.iprFlatInCents : 0);
    final cnss = take(
      PayrollMath.roundDiv(baseInCents * perCurrency.cnssPermille, 1000),
    );
    final childcare = take(_positive(variables?.childcareInCents));
    return PayrollLineDeductions(
      workDaysDivisor: hourly ? null : divisor,
      workedDays: worked,
      absenceInCents: absence,
      iprInCents: ipr,
      cnssInCents: cnss,
      childcareInCents: childcare,
    );
  }

  /// Les jours prestés : la saisie de l'économe, sinon le Pointage de M−1 ;
  /// sans résumé (M−1 hors année), le mois entier.
  static int workedDaysOf({
    required int divisor,
    required int? variable,
    required AttendanceAgentSummary? attendance,
  }) {
    if (divisor <= 0) return 0;
    final raw =
        variable ??
        (attendance == null
            ? divisor
            : divisor - attendance.unjustifiedAbsences);
    if (raw < 0) return 0;
    return raw > divisor ? divisor : raw;
  }

  /// Le versement du mois : le montant fixe de l'agent prime (borné au net),
  /// sinon `roundDiv(net × taux, 100)`.
  static PayrollLinePayout payout({
    required int netInCents,
    required int ratePercent,
    required int? fixedInCents,
  }) {
    if (fixedInCents != null) {
      final fixed = _positive(fixedInCents);
      final toPay = fixed < netInCents ? fixed : netInCents;
      return PayrollLinePayout(
        toPayInCents: toPay,
        deferredInCents: netInCents - toPay,
        fixed: true,
      );
    }
    final rate = ratePercent.clamp(0, 100);
    final toPay = PayrollMath.roundDiv(netInCents * rate, 100);
    return PayrollLinePayout(
      toPayInCents: toPay,
      deferredInCents: netInCents - toPay,
      ratePercent: rate,
    );
  }

  static int _positive(int? cents) => cents == null || cents < 0 ? 0 : cents;
}
