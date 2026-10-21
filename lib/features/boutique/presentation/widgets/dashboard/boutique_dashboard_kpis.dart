import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/kpi_delta.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres clés. Une seule tuile pleine — **Recettes** —, parce que
/// c'est le chiffre qu'on vient chercher ; les trois autres l'expliquent.
///
/// Recettes et panier moyen portent **une valeur par devise**, empilées :
/// 425,00 $ et 90 000 FC ne se somment pas.
class BoutiqueDashboardKpis extends StatelessWidget {
  final BoutiqueStats stats;

  /// Faux quand la fenêtre précédente chevauche la rentrée : aucun delta.
  final bool deltaComparable;

  const BoutiqueDashboardKpis({
    super.key,
    required this.stats,
    required this.deltaComparable,
  });

  static const int _softTint = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocks = stats.byCurrency;
    final none = [l10n.boutiqueDashboardKpiNone];

    String? delta(int? current, int? previous) {
      final text = KpiDelta.of(current, previous, comparable: deltaComparable);
      return text == null ? null : l10n.boutiqueDashboardKpiDelta(text);
    }

    final revenue = [
      for (final b in blocks) Money.parse(b.revenue, b.currency),
    ];
    final previousRevenue = [
      for (final b in blocks)
        if (b.previousRevenue > 0) Money.parse(b.previousRevenue, b.currency),
    ];
    final baskets = [
      for (final b in blocks)
        if (b.averageBasket != null) Money.parse(b.averageBasket!, b.currency),
    ];
    // Le delta du panier n'a de sens que dans UNE devise.
    final single = blocks.length == 1 ? blocks.single : null;

    return EteeloKpiBand(
      cards: [
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiRevenue,
          valueLines: revenue.isEmpty
              ? none
              : BoutiqueDashboardLabels.moneyLines(revenue),
          accent: AppColors.blancCasse,
          accentSoft: AppColors.terreCuiteDark,
          icon: Icons.payments_outlined,
          filledBackground: AppColors.terreCuiteInk,
          // Le précédent en clair, pas un pourcentage : une recette se
          // compare à une recette.
          subline: deltaComparable && previousRevenue.isNotEmpty
              ? l10n.boutiqueDashboardKpiPrevious(
                  BoutiqueDashboardLabels.moneyInline(previousRevenue),
                )
              : null,
        ),
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiSales,
          value: stats.saleCount,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoiseSoft,
          icon: Icons.receipt_long_outlined,
          subline: delta(stats.saleCount, stats.previousSaleCount),
        ),
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiAverageBasket,
          valueLines: baskets.isEmpty
              ? none
              : BoutiqueDashboardLabels.moneyLines(baskets),
          accent: AppColors.vertSavane,
          accentSoft: ColorMix.tint(
            AppColors.surfaceRaised,
            AppColors.vertSavane,
            _softTint,
          ),
          icon: Icons.shopping_basket_outlined,
          subline: single == null
              ? null
              : delta(single.averageBasket, single.previousAverageBasket),
        ),
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiArticles,
          value: stats.articleCount,
          accent: AppColors.boutiqueActesAccent,
          accentSoft: ColorMix.tint(
            AppColors.surfaceRaised,
            AppColors.boutiqueActesAccent,
            _softTint,
          ),
          icon: Icons.inventory_2_outlined,
          subline: delta(stats.articleCount, stats.previousArticleCount),
        ),
      ],
    );
  }
}
