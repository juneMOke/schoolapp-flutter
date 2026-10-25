import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settings.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_math.dart';

/// Le tableau de bord de la paie (spec TB 1-2), calculé sur la tablette à
/// partir des mêmes lignes que le livre : le PDF du serveur (Q7) applique
/// les mêmes définitions aux mêmes lignes.
abstract final class PayrollDashboard {
  static bool _validated(PayrollMonthView view) =>
      view.header?.status == PayrollStatus.validated;

  /// Les devises du mois, la plus représentée d'abord.
  static List<String> currenciesOf(PayrollMonthView view) {
    final counts = <String, int>{};
    for (final line in view.lines) {
      counts[line.currency] = (counts[line.currency] ?? 0) + 1;
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  static PayrollForecast forecastOf(PayrollMonthView view, String currency) {
    var gross = 0, absence = 0, advances = 0, legal = 0, childcare = 0;
    var net = 0;
    for (final line in view.lines) {
      if (line.currency != currency) continue;
      gross += line.grossInCents;
      absence += line.deductions.absenceInCents;
      advances += line.advanceInCents;
      legal += line.deductions.iprInCents + line.deductions.cnssInCents;
      childcare += line.deductions.childcareInCents;
      net += line.netInCents;
    }
    return PayrollForecast(
      grossInCents: gross,
      absenceInCents: absence,
      advancesInCents: advances,
      legalInCents: legal,
      childcareInCents: childcare,
      netInCents: net,
    );
  }

  static PayrollNetProgress progressOf(PayrollMonthView view, String currency) {
    final lines = view.lines.where(
      (line) => line.currency == currency && line.netInCents > 0,
    );
    // Une paie d'avant la v2 : ses versements n'étaient pas saisis, un
    // « non payé » y serait faux.
    if (!isTracked(view)) return const PayrollNetProgress();
    if (!_validated(view)) {
      return PayrollNetProgress(
        notYetInCents: lines.fold(0, (sum, line) => sum + line.netInCents),
      );
    }
    var paid = 0, deferred = 0, unpaid = 0;
    var settled = 0, partial = 0, none = 0;
    for (final line in lines) {
      final settlement = view.settlementOf(line);
      final received = settlement.paidInCents.clamp(0, line.netInCents);
      final remaining = line.netInCents - received;
      // La part différée par décision et pas encore versée est « reportée » ;
      // le reste du dû est « non payé ».
      final decided = line.deferredInCents.clamp(0, remaining);
      paid += received;
      deferred += decided;
      unpaid += remaining - decided;
      if (remaining == 0) {
        settled++;
      } else if (received > 0) {
        partial++;
      } else {
        none++;
      }
    }
    return PayrollNetProgress(
      paidInCents: paid,
      deferredInCents: deferred,
      unpaidInCents: unpaid,
      settledCount: settled,
      partialCount: partial,
      unpaidCount: none,
    );
  }

  /// Les charges patronales (CNSS, INPP, ONEM) sur le brut du mois, arrondies
  /// au centime : le coût employeur, que rien ne retient sur le bulletin.
  static int employerChargesOf(
    PayrollForecast forecast,
    PayrollSettings settings,
  ) => PayrollMath.roundDiv(
    forecast.grossInCents * settings.employerChargesPermille,
    1000,
  );

  /// Une paie validée avant la v2 : on payait sans saisir le versement, rien
  /// ne s'y suit (le serveur refuse son PDF : `PAYROLL_NOT_TRACKED`).
  static bool isTracked(PayrollMonthView view) =>
      view.lines.every((line) => line.formulaVersion >= 2);

  /// Une ligne par agent payé ce mois, arriérés antérieurs compris ; plus une
  /// ligne par agent et devise que seuls ses arriérés y mettent.
  static List<PayrollDashboardRow> rowsOf(
    PayrollMonthView view,
    List<PayrollArrearsAgent> arrears,
  ) {
    final validated = _validated(view);
    // Les arriérés des mois antérieurs, par agent puis devise.
    final owed = <String, Map<String, int>>{};
    for (final agent in arrears) {
      for (final arrear in agent.months) {
        if (arrear.month.compareTo(view.month) >= 0) continue;
        final byCurrency = owed[agent.staffMemberId] ??= {};
        byCurrency[arrear.currency] =
            (byCurrency[arrear.currency] ?? 0) + arrear.dueInCents;
      }
    }
    final rows = [
      for (final line in view.lines)
        _row(
          staffMemberId: line.staffMemberId,
          currency: line.currency,
          planned: line.grossInCents,
          deductions: line.deductions.totalInCents + line.advanceInCents,
          net: line.netInCents,
          arrears: owed[line.staffMemberId]?.remove(line.currency) ?? 0,
          received: validated ? view.settlementOf(line).paidInCents : 0,
          validated: validated,
        ),
    ];
    owed.forEach((staffMemberId, byCurrency) {
      byCurrency.forEach((currency, due) {
        if (due <= 0) return;
        rows.add(
          _row(
            staffMemberId: staffMemberId,
            currency: currency,
            planned: 0,
            deductions: 0,
            net: 0,
            arrears: due,
            received: 0,
            validated: validated,
          ),
        );
      });
    });
    return rows;
  }

  static PayrollDashboardRow _row({
    required String staffMemberId,
    required String currency,
    required int planned,
    required int deductions,
    required int net,
    required int arrears,
    required int received,
    required bool validated,
  }) {
    final remaining = net + arrears - received;
    return PayrollDashboardRow(
      staffMemberId: staffMemberId,
      currency: currency,
      netInCents: net,
      plannedInCents: planned,
      deductionsInCents: deductions,
      arrearsInCents: arrears,
      receivedInCents: received,
      status: !validated
          ? PayrollDashboardStatus.toDisburse
          : remaining <= 0
          ? PayrollDashboardStatus.settled
          : received > 0
          ? PayrollDashboardStatus.partial
          : PayrollDashboardStatus.due,
    );
  }
}
