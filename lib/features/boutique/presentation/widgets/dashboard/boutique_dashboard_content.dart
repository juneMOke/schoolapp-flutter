import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/stats_bucket_keys.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_top_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_dashboard_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_beneficiaries_card.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_currency_selector.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_kpis.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_family_card.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_latest_sales_card.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_revenue_chart_card.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_top_articles_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'écran prêt : une colonne qui descend du plus synthétique au plus
/// détaillé — chiffres → temps → contenu → élèves → reçus.
class BoutiqueDashboardContent extends StatelessWidget {
  final BoutiqueDashboardState state;
  final BoutiqueStats stats;
  final DateTime now;
  final GlobalKey beneficiariesKey;
  final ValueChanged<String> onCurrencySelected;
  final void Function(BoutiqueTopArticle article) onArticleTap;
  final ValueChanged<SaleHistoryEntry> onOpenSale;
  final VoidCallback onOpenTill;

  const BoutiqueDashboardContent({
    super.key,
    required this.state,
    required this.stats,
    required this.now,
    required this.beneficiariesKey,
    required this.onCurrencySelected,
    required this.onArticleTap,
    required this.onOpenSale,
    required this.onOpenTill,
  });

  static const double _gap = AppDimensions.spacingM;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final block = state.selectedBlock;
    final family = block == null ? null : BoutiqueFamilyCard(block: block);
    final top = stats.topArticles.isEmpty
        ? null
        : BoutiqueTopArticlesCard(
            articles: stats.topArticles,
            onArticleTap: onArticleTap,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoutiqueDashboardKpis(
          stats: stats,
          deltaComparable: state.isDeltaComparable,
        ),
        if (block != null) ...[
          const SizedBox(height: _gap),
          BoutiqueRevenueChartCard(
            block: block,
            granularity: stats.granularity,
            currentKey: StatsBucketKeys.of(now, stats.granularity),
            currencySelector: BoutiqueCurrencySelector(
              currencies: [for (final b in stats.byCurrency) b.currency],
              selected: state.selectedCurrency,
              onSelected: onCurrencySelected,
            ),
          ),
        ],
        if (family != null || top != null) ...[
          const SizedBox(height: _gap),
          _SideBySide(first: family, second: top),
        ],
        const SizedBox(height: _gap),
        BoutiqueBeneficiariesCard(key: beneficiariesKey),
        const SizedBox(height: _gap),
        BoutiqueLatestSalesCard(
          sales: state.latestSales,
          onOpenSale: onOpenSale,
          onNewSale: onOpenTill,
        ),
        const SizedBox(height: _gap),
        Text(
          l10n.boutiqueDashboardFooterNote,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMutedAa,
          ),
        ),
      ],
    );
  }
}

/// Familles et palmarès côte à côte dès qu'ils tiennent, l'un sous l'autre
/// sinon — alignés en haut, jamais étirés à la même hauteur.
class _SideBySide extends StatelessWidget {
  final Widget? first;
  final Widget? second;

  const _SideBySide({this.first, this.second});

  @override
  Widget build(BuildContext context) {
    final cards = [?first, ?second];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (cards.length < 2 ||
            constraints.maxWidth < AppBreakpoints.detailCompactMax) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: AppDimensions.spacingM),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }
}
