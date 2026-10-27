import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_agent_situation.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';

/// La fiche de paie d'un agent (spec « Livre & fiche agent »), composée des
/// livres déjà calculés — lecture 100 % locale, aucun calcul de paie refait.
abstract final class PayrollAgentSituations {
  /// La situation de [staffMemberId] dans [history] (les livres du plus
  /// récent au plus ancien), les cumuls sur l'année civile [year] (`YYYY`).
  static PayrollAgentSituation of(
    PayrollSnapshot snapshot,
    List<PayrollMonthView> history, {
    required String staffMemberId,
    required String year,
    required String currentMonth,
  }) {
    final months = [
      for (final view in history)
        if (view.line(staffMemberId) case final line?)
          PayrollAgentMonth(view: view, line: line),
    ]..sort((a, b) => b.month.compareTo(a.month));

    final outstanding = <String, int>{};
    var unsettled = 0;
    final totals = <String, PayrollAgentTotals>{};
    for (final month in months) {
      if (!month.isFrozen) continue;
      final line = month.line;
      final remaining = month.remainingInCents;
      if (remaining > 0) {
        unsettled++;
        outstanding[line.currency] =
            (outstanding[line.currency] ?? 0) + remaining;
      }
      if (month.month.startsWith('$year-')) {
        totals[line.currency] =
            (totals[line.currency] ??
                    PayrollAgentTotals(currency: line.currency))
                .add(month);
      }
    }

    final advances =
        snapshot.advances
            .where((advance) => advance.staffMemberId == staffMemberId)
            .toList()
          ..sort((a, b) => b.grantedOn.compareTo(a.grantedOn));
    // Une demande payée a fait naître son avance : elle se lit là. Une
    // demande reprise par son auteur n'existe plus pour l'agent.
    final requests = snapshot.advanceRequests
        .where(
          (request) =>
              request.staffMemberId == staffMemberId &&
              (request.isInCircuit || request.status == ExpenseStatus.refused),
        )
        .toList();

    final arrears = PayrollArrears.of(
      snapshot,
      currentMonth: currentMonth,
    ).where((agent) => agent.staffMemberId == staffMemberId).firstOrNull;

    return PayrollAgentSituation(
      staffMemberId: staffMemberId,
      year: year,
      months: months,
      outstanding: outstanding,
      unsettledMonths: unsettled,
      totals: totals.values.toList()
        ..sort((a, b) => a.currency.compareTo(b.currency)),
      advances: advances,
      requests: requests,
      arrears: arrears,
    );
  }

  /// L'ordre de parcours de la fiche — précédent / suivant : les agents du
  /// livre de [view] dans l'ordre de l'état civil, sans les filtres.
  static List<String> roster(PayrollSnapshot snapshot, PayrollMonthView view) =>
      [for (final line in ordered(snapshot, view.lines)) line.staffMemberId];

  /// [lines] dans l'ordre de l'état civil ; la ligne figée d'un agent retiré
  /// depuis la validation reste, en fin de liste.
  static List<PayrollLine> ordered(
    PayrollSnapshot snapshot,
    Iterable<PayrollLine> lines,
  ) {
    final order = {
      for (final (index, member) in snapshot.members.indexed) member.id: index,
    };
    return lines.toList()..sort(
      (a, b) => (order[a.staffMemberId] ?? order.length).compareTo(
        order[b.staffMemberId] ?? order.length,
      ),
    );
  }
}
