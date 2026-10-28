import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line_parts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_working_days.dart';

/// Les retenues fixes et le versement du mois (formule 3) : des fonctions
/// pures, en centimes, une seule division par montant (T2).
///
/// ```text
/// J        jours ouvrés du mois civil M : lundi au vendredi, vacances
///          comprises, sans fériés (V1)
/// NJ       absences non justifiées du Pointage de M, bornées à [0, J]
///          mois ouvert ou hors année : 0 · vacataire à l'heure : sans objet
/// absence  réglage actif ? min(roundDiv(base × NJ, J), base) : 0
/// IPR      brut > 0 ? forfait[devise] : 0
/// CNSS     roundDiv(base × ‰[devise], 1000)        (base avant absence, T4)
/// PC/E     variable ?? 0
/// ```
/// Pris sur le brut dans cet ordre, chacun borné à ce qui reste (T3).
abstract final class PayrollDeductions {
  static PayrollLineDeductions compute({
    required String month,
    required bool hourly,
    required int baseInCents,
    required int grossInCents,
    required PayrollSettings settings,
    required PayrollCurrencySettings perCurrency,
    required PayrollVariables? variables,
    required AttendanceAgentSummary attendance,
  }) {
    final workingDays = hourly ? null : PayrollWorkingDays.of(month);
    final absences = workingDays == null
        ? null
        : unjustifiedAbsences(attendance, workingDays);
    var capacity = grossInCents;
    int take(int amount) {
      final taken = amount < capacity ? amount : capacity;
      capacity -= taken;
      return taken;
    }

    final absence = take(
      workingDays != null &&
              absences != null &&
              settings.absenceDeductionEnabled &&
              workingDays > 0
          ? _absence(baseInCents, absences, workingDays)
          : 0,
    );
    final ipr = take(grossInCents > 0 ? perCurrency.iprFlatInCents : 0);
    final cnss = take(
      PayrollMath.roundDiv(baseInCents * perCurrency.cnssPermille, 1000),
    );
    // Coupée par l'école (Q8), la PC/E compte 0 — le montant saisi reste
    // rangé, et revient si on la rallume. Même règle au serveur.
    final childcare = take(
      settings.childcareEnabled ? _positive(variables?.childcareInCents) : 0,
    );
    return PayrollLineDeductions(
      workDaysDivisor: workingDays,
      unjustifiedAbsences: absences,
      absenceInCents: absence,
      iprInCents: ipr,
      cnssInCents: cnss,
      childcareInCents: childcare,
    );
  }

  /// NJ : les absences non justifiées du mois, bornées à [0, J].
  static int unjustifiedAbsences(
    AttendanceAgentSummary attendance,
    int workingDays,
  ) => attendance.unjustifiedAbsences.clamp(0, workingDays);

  /// `min(roundDiv(base × NJ, J), base)` : jamais plus que la base.
  static int _absence(int base, int absences, int workingDays) {
    final amount = PayrollMath.roundDiv(base * absences, workingDays);
    return amount < base ? amount : base;
  }

  /// Le versement du mois : le montant fixe de l'agent prime (borné au net),
  /// sinon `roundDiv(net × taux, 100)`. Le motif suit ce qui a joué : celui
  /// du montant fixe, ou celui du taux — aucun à 100 %.
  static PayrollLinePayout payout({
    required int netInCents,
    required int ratePercent,
    required int? fixedInCents,
    String? rateReason,
    String? fixedReason,
  }) {
    if (fixedInCents != null) {
      final fixed = _positive(fixedInCents);
      final toPay = fixed < netInCents ? fixed : netInCents;
      return PayrollLinePayout(
        toPayInCents: toPay,
        deferredInCents: netInCents - toPay,
        fixedInCents: fixed,
        reason: fixedReason,
      );
    }
    final rate = ratePercent.clamp(0, 100);
    final toPay = PayrollMath.roundDiv(netInCents * rate, 100);
    return PayrollLinePayout(
      toPayInCents: toPay,
      deferredInCents: netInCents - toPay,
      ratePercent: rate,
      reason: rate == 100 ? null : rateReason,
    );
  }

  static int _positive(int? cents) => cents == null || cents < 0 ? 0 : cents;
}
