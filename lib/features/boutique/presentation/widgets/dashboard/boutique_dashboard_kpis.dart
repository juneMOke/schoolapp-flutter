import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/kpi_delta.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres clés, **en pavés pleins** — le modèle des caisses du
/// tableau de bord Finances : chaque chiffre a sa teinte, sa flèche de
/// tendance, et dit quand la comparaison est impossible.
///
/// Chaque pavé garde la teinte que sa carte claire portait déjà — terre cuite
/// pour les recettes (la marque de la boutique), bleu ardoise pour les ventes,
/// vert pour le panier, violet pour les articles — passée par la formule
/// partagée [DashboardTones.pave] : un pavé Boutique et un pavé Finances
/// sortent du même mélange.
///
/// Recettes et panier moyen portent **une valeur par devise**, empilées :
/// 425,00 $ et 90 000 FC ne se somment pas.
class BoutiqueDashboardKpis extends StatelessWidget {
  final BoutiqueStats stats;

  /// Faux quand la fenêtre précédente chevauche la rentrée : aucun delta, et
  /// chaque pavé le dit.
  final bool deltaComparable;

  const BoutiqueDashboardKpis({
    super.key,
    required this.stats,
    required this.deltaComparable,
  });

  static Color _fond(Color accent) =>
      DashboardTones.pave(DashboardTones.paveAccentSur(accent));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocks = stats.byCurrency;
    final none = [l10n.boutiqueDashboardKpiNone];
    // Deux silences très différents, comme à la caisse : une comparaison
    // IMPOSSIBLE se dit — sinon les pavés perdent leur flèche tous les jours de
    // septembre sans raison visible —, une période précédente simplement vide
    // se tait.
    final noComparable = deltaComparable
        ? null
        : l10n.boutiqueDashboardKpiNoComparable;

    EteeloKpiTrend? trend(int? current, int? previous) {
      final text = KpiDelta.of(current, previous, comparable: deltaComparable);
      if (text == null) return null;
      return EteeloKpiTrend(
        rising: !KpiDelta.isDown(current, previous),
        label: l10n.boutiqueDashboardKpiDelta(text),
      );
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
    // Un pourcentage de montant n'a de sens que dans UNE devise.
    final single = blocks.length == 1 ? blocks.single : null;

    const revenueAccent = DashboardSense.marque;
    const salesAccent = AppColors.bleuArdoise;
    const basketAccent = AppColors.vertSavane;
    const articlesAccent = AppColors.boutiqueActesAccent;

    return EteeloKpiBand(
      cards: [
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiRevenue,
          valueLines: revenue.isEmpty
              ? none
              : BoutiqueDashboardLabels.moneyLines(revenue),
          accent: revenueAccent,
          accentSoft: revenueAccent,
          icon: Icons.payments_outlined,
          filledBackground: _fond(revenueAccent),
          filledSecondaryInk: DashboardTones.encreSecondeValeur(revenueAccent),
          // Le précédent en clair : une recette se compare à une recette. Le
          // pourcentage, lui, ne se calcule que dans une seule devise.
          subline:
              noComparable ??
              (previousRevenue.isEmpty
                  ? null
                  : l10n.boutiqueDashboardKpiPrevious(
                      BoutiqueDashboardLabels.moneyInline(previousRevenue),
                    )),
          trend: single == null
              ? null
              : trend(single.revenue, single.previousRevenue),
        ),
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiSales,
          value: stats.saleCount,
          accent: salesAccent,
          accentSoft: salesAccent,
          icon: Icons.receipt_long_outlined,
          filledBackground: _fond(salesAccent),
          subline: noComparable,
          trend: trend(stats.saleCount, stats.previousSaleCount),
        ),
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiAverageBasket,
          valueLines: baskets.isEmpty
              ? none
              : BoutiqueDashboardLabels.moneyLines(baskets),
          accent: basketAccent,
          accentSoft: basketAccent,
          icon: Icons.shopping_basket_outlined,
          filledBackground: _fond(basketAccent),
          filledSecondaryInk: DashboardTones.encreSecondeValeur(basketAccent),
          subline: noComparable,
          trend: single == null
              ? null
              : trend(single.averageBasket, single.previousAverageBasket),
        ),
        EteeloKpiCardData(
          label: l10n.boutiqueDashboardKpiArticles,
          value: stats.articleCount,
          accent: articlesAccent,
          accentSoft: articlesAccent,
          icon: Icons.inventory_2_outlined,
          filledBackground: _fond(articlesAccent),
          subline: noComparable,
          trend: trend(stats.articleCount, stats.previousArticleCount),
        ),
      ],
    );
  }
}
