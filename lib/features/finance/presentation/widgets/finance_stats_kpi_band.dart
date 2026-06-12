import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bande KPI du tableau de bord Finances, adaptée aux données [FinanceKpis].
///
/// Réutilise le composant DS partagé [EteeloKpiBand]/[KpiCard] — même rendu en cartes
/// et même responsivité (grille auto-fill, aucun scroll horizontal) que le
/// tableau de bord Inscription. Les montants sont en **cents** côté entité →
/// formatés en devise pour l'affichage ; le taux est un pourcentage.
class FinanceStatsKpiBand extends StatelessWidget {
  final FinanceKpis kpis;
  final FeeTypeDistribution distribution;

  const FinanceStatsKpiBand({
    super.key,
    required this.kpis,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalByFeeType = distribution.items.fold<int>(
      0,
      (sum, e) => sum + e.expected,
    );

    return Semantics(
      container: true,
      label: l10n.financeStatsKpiBandA11yLabel,
      child: EteeloKpiBand(
        cards: [
          EteeloKpiCardData(
            label: l10n.financeStatsKpiCollected,
            valueText: _money(kpis.collected),
            accent: AppColors.feeStatusPaid,
            accentSoft: AppColors.feeStatusPaidSoft,
            icon: Icons.payments_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeStatsKpiExpected,
            valueText: _money(kpis.expected),
            percent: _safePercent(value: kpis.expected, total: totalByFeeType),
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.billingHelpSurface,
            icon: Icons.receipt_long_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeStatsKpiOutstanding,
            valueText: _money(kpis.outstanding),
            percent: _safePercent(
              value: kpis.outstanding,
              total: totalByFeeType,
            ),
            accent: AppColors.feeStatusDue,
            accentSoft: AppColors.feeStatusDueSoft,
            icon: Icons.pending_actions_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.financeStatsKpiCollectionRate,
            valueText: '${kpis.collectionRate}%',
            accent: AppColors.feeStatusPartial,
            accentSoft: AppColors.feeStatusPartialSoft,
            icon: Icons.percent_rounded,
          ),
        ],
      ),
    );
  }

  String _money(int amountInCents) => formatMonetaryAmount(amountInCents / 100);

  int _safePercent({required int value, required int total}) {
    if (total <= 0) return 0;
    return ((value * 100) / total).round();
  }
}
