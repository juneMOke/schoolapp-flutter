import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_deductions.dart';

/// Ce qu'un taux de versement donnerait sur un livre, par devise : le net
/// dû, ce qui serait versé, ce qui deviendrait un arriéré. Les agents à
/// montant fixe gardent leur montant — le même calcul que le moteur.
class PayrollPayoutTotals {
  final String currency;
  final int dueInCents;
  final int toPayInCents;

  const PayrollPayoutTotals({
    required this.currency,
    required this.dueInCents,
    required this.toPayInCents,
  });

  int get deferredInCents => dueInCents - toPayInCents;
}

abstract final class PayrollPayoutPreview {
  /// Triés par devise.
  static List<PayrollPayoutTotals> at(List<PayrollLine> lines, int rate) {
    final due = <String, int>{};
    final toPay = <String, int>{};
    for (final line in lines) {
      final paid = line.payout?.fixed ?? false
          ? line.toPayInCents
          : PayrollDeductions.payout(
              netInCents: line.netInCents,
              ratePercent: rate,
              fixedInCents: null,
            ).toPayInCents;
      due[line.currency] = (due[line.currency] ?? 0) + line.netInCents;
      toPay[line.currency] = (toPay[line.currency] ?? 0) + paid;
    }
    final currencies = due.keys.toList()..sort();
    return [
      for (final currency in currencies)
        PayrollPayoutTotals(
          currency: currency,
          dueInCents: due[currency]!,
          toPayInCents: toPay[currency]!,
        ),
    ];
  }

  /// Les agents dont le versement est réduit ce mois-ci.
  static int reducedCount(List<PayrollLine> lines) =>
      lines.where((line) => line.deferredInCents > 0).length;
}
