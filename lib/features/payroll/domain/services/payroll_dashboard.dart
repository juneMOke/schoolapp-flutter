import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_dashboard_figures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';

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

  /// Une ligne par agent payé ce mois, arriérés antérieurs compris.
  static List<PayrollDashboardRow> rowsOf(
    PayrollMonthView view,
    List<PayrollArrearsAgent> arrears,
  ) {
    final validated = _validated(view);
    final arrearsOf = <String, List<PayrollArrear>>{
      for (final agent in arrears) agent.staffMemberId: agent.months,
    };
    return [
      for (final line in view.lines)
        _row(
          line,
          validated: validated,
          received: validated ? view.settlementOf(line).paidInCents : 0,
          arrears: [
            for (final arrear in arrearsOf[line.staffMemberId] ?? const [])
              if (arrear.month.compareTo(view.month) < 0 &&
                  arrear.currency == line.currency)
                arrear,
          ],
        ),
    ];
  }

  static PayrollDashboardRow _row(
    PayrollLine line, {
    required bool validated,
    required int received,
    required List<PayrollArrear> arrears,
  }) {
    final arrearsInCents = arrears.fold(0, (sum, a) => sum + a.dueInCents);
    final row = PayrollDashboardRow(
      line: line,
      plannedInCents: line.grossInCents,
      deductionsInCents: line.deductions.totalInCents + line.advanceInCents,
      arrearsInCents: arrearsInCents,
      receivedInCents: received,
      status: PayrollDashboardStatus.toDisburse,
    );
    if (!validated) return row;
    return PayrollDashboardRow(
      line: line,
      plannedInCents: row.plannedInCents,
      deductionsInCents: row.deductionsInCents,
      arrearsInCents: arrearsInCents,
      receivedInCents: received,
      status: row.remainingInCents == 0
          ? PayrollDashboardStatus.settled
          : received > 0
          ? PayrollDashboardStatus.partial
          : PayrollDashboardStatus.due,
    );
  }
}
