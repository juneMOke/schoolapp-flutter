import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';

/// Le registre des arriérés (B4), dérivé des paies validées et de leurs
/// versements vivants — lecture 100 % locale.
abstract final class PayrollArrears {
  /// Par agent, le mois le plus ancien d'abord, puis le montant dû.
  ///
  /// Le mois en cours ([currentMonth]) n'y entre que pour sa part différée
  /// par décision : un salaire du mois pas encore versé n'est pas en retard.
  static List<PayrollArrearsAgent> of(
    PayrollSnapshot snapshot, {
    required String currentMonth,
  }) {
    final byAgent = <String, List<PayrollArrear>>{};
    final months = snapshot.headers.keys.toList()..sort();
    for (final month in months) {
      final header = snapshot.headers[month]!;
      final validation = header.validationGestureId;
      final lines = snapshot.frozenLines[month];
      if (header.status != PayrollStatus.validated ||
          validation == null ||
          lines == null ||
          month.compareTo(currentMonth) > 0) {
        continue;
      }
      final view = PayrollLedger.monthView(snapshot, month);
      for (final line in lines) {
        final settlement = view.settlementOf(line);
        final remaining = settlement.remainingInCents;
        if (remaining <= 0) continue;
        final current = month == currentMonth;
        // Le mois en cours : la part différée par décision, quoi qu'on ait
        // déjà versé de la part prévue — le reste n'est pas en retard.
        if (current && line.deferredInCents <= 0) continue;
        final due = current
            ? (line.deferredInCents < remaining
                  ? line.deferredInCents
                  : remaining)
            : remaining;
        final origin = current
            ? PayrollArrearOrigin.deferred
            : switch (settlement.status) {
                PayrollSettlementStatus.deferred =>
                  PayrollArrearOrigin.deferred,
                PayrollSettlementStatus.partial => PayrollArrearOrigin.partial,
                _ => PayrollArrearOrigin.unpaid,
              };
        final variables = snapshot.variables[month]?[line.staffMemberId];
        (byAgent[line.staffMemberId] ??= []).add(
          PayrollArrear(
            line: line,
            validationGestureId: validation,
            paidInCents: settlement.paidInCents,
            dueInCents: due,
            origin: origin,
            prioritized: snapshot.arrearsPriorities.contains(
              priorityKey(month, line.staffMemberId),
            ),
            reason: line.payout?.fixed ?? false
                ? variables?.fixedPayoutReason
                : snapshot.payoutPolicies[month]?.reason,
          ),
        );
      }
    }
    final agents = [
      for (final entry in byAgent.entries)
        PayrollArrearsAgent(staffMemberId: entry.key, months: entry.value),
    ];
    agents.sort((a, b) {
      final byMonth = a.oldestMonth.compareTo(b.oldestMonth);
      if (byMonth != 0) return byMonth;
      return _total(b).compareTo(_total(a));
    });
    return agents;
  }

  static String priorityKey(String month, String staffMemberId) =>
      '$month|$staffMemberId';

  static int _total(PayrollArrearsAgent agent) =>
      agent.months.fold(0, (sum, arrear) => sum + arrear.dueInCents);

  /// La répartition d'un versement de [amountInCents] en [currency] : du mois
  /// le plus ancien au plus récent, un versement par mois d'origine, jamais
  /// au-delà de ce qui y est dû.
  static List<(PayrollArrear, int)> split(
    PayrollArrearsAgent agent,
    String currency,
    int amountInCents,
  ) {
    var left = amountInCents;
    final result = <(PayrollArrear, int)>[];
    for (final arrear in agent.months) {
      if (left <= 0) break;
      if (arrear.currency != currency) continue;
      final take = arrear.dueInCents < left ? arrear.dueInCents : left;
      if (take <= 0) continue;
      result.add((arrear, take));
      left -= take;
    }
    return result;
  }
}
