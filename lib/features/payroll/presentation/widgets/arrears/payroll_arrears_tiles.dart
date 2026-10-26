import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_kpi_card.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre tuiles du registre : la dette salariale, le différé décidé, les
/// impayés et acomptes, le plus ancien mois dû.
class PayrollArrearsTiles extends StatelessWidget {
  final List<PayrollArrearsAgent> agents;
  final String currentMonth;

  const PayrollArrearsTiles({
    super.key,
    required this.agents,
    required this.currentMonth,
  });

  static List<String> _sum(
    Iterable<PayrollArrear> arrears,
    bool Function(PayrollArrear arrear) keep,
  ) => PayrollLabels.perCurrency([
    for (final arrear in arrears)
      if (keep(arrear)) (arrear.dueInCents, arrear.currency),
  ]);

  /// Les mois écoulés entre deux `YYYY-MM`.
  static int monthsBetween(String from, String to) {
    int index(String month) =>
        int.parse(month.substring(0, 4)) * 12 + int.parse(month.substring(5));
    return index(to) - index(from);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = [for (final agent in agents) ...agent.months];
    final oldest = agents.isEmpty
        ? null
        : (agents.map((a) => a.oldestMonth).toList()..sort()).first;
    return EteeloKpiBand(
      cards: [
        PayrollKpiCard.of(
          label: l10n.payrollArrearsDebt,
          valueLines: _sum(all, (_) => true),
          accent: DashboardSense.manquant,
          icon: Icons.account_balance_outlined,
          subline: l10n.payrollKpiAgents(agents.length),
        ),
        PayrollKpiCard.of(
          label: l10n.payrollArrearsDeferred,
          valueLines: _sum(
            all,
            (a) => a.origin == PayrollArrearOrigin.deferred,
          ),
          // Différé par décision : une attente, pas un statut « validée ».
          accent: DashboardSense.attente,
          icon: Icons.hourglass_bottom,
        ),
        PayrollKpiCard.of(
          label: l10n.payrollArrearsUnpaid,
          valueLines: _sum(
            all,
            (a) => a.origin != PayrollArrearOrigin.deferred,
          ),
          accent: DashboardSense.manquant,
          icon: Icons.money_off_outlined,
        ),
        PayrollKpiCard.of(
          label: l10n.payrollArrearsOldest,
          valueLines: [
            oldest == null ? '—' : PayrollLabels.month(context, oldest),
          ],
          accent: DashboardSense.marque,
          icon: Icons.history,
          subline: oldest == null
              ? null
              : l10n.payrollArrearsAge(monthsBetween(oldest, currentMonth)),
        ),
      ],
    );
  }
}
