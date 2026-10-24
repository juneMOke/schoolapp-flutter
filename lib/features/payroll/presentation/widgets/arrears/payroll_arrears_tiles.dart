import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
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
        EteeloKpiCardData(
          label: l10n.payrollArrearsDebt,
          valueLines: _sum(all, (_) => true),
          accent: AppColors.presenceMarkOnBanner,
          accentSoft: AppColors.presenceMarkBannerMid,
          icon: Icons.account_balance_outlined,
          filledBackground: AppColors.presenceMarkBannerStart,
          filledSecondaryInk: AppColors.presenceMarkOnBannerMuted,
          subline: l10n.payrollKpiAgents(agents.length),
        ),
        EteeloKpiCardData(
          label: l10n.payrollArrearsDeferred,
          valueLines: _sum(
            all,
            (a) => a.origin == PayrollArrearOrigin.deferred,
          ),
          accent: PayrollTone.submitted.ink,
          accentSoft: PayrollTone.submitted.soft,
          icon: Icons.hourglass_bottom,
        ),
        EteeloKpiCardData(
          label: l10n.payrollArrearsUnpaid,
          valueLines: _sum(
            all,
            (a) => a.origin != PayrollArrearOrigin.deferred,
          ),
          accent: PayrollTone.alert.ink,
          accentSoft: PayrollTone.alert.soft,
          icon: Icons.money_off_outlined,
        ),
        EteeloKpiCardData(
          label: l10n.payrollArrearsOldest,
          valueLines: [
            oldest == null ? '—' : PayrollLabels.month(context, oldest),
          ],
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoiseSoft,
          icon: Icons.history,
          subline: oldest == null
              ? null
              : l10n.payrollArrearsAge(monthsBetween(oldest, currentMonth)),
        ),
      ],
    );
  }
}
