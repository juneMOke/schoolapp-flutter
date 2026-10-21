import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_top_article.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cinq articles les plus vendus **en quantité**. Chaque ligne est une
/// porte vers les élèves : la toucher filtre la liste sur cet article.
class BoutiqueTopArticlesCard extends StatelessWidget {
  final List<BoutiqueTopArticle> articles;
  final void Function(BoutiqueTopArticle article) onArticleTap;

  const BoutiqueTopArticlesCard({
    super.key,
    required this.articles,
    required this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloStatsCard(
      title: l10n.boutiqueDashboardTopTitle,
      subtitle: l10n.boutiqueDashboardTopSubtitle,
      icon: Icons.emoji_events_outlined,
      iconColor: AppColors.terreCuite,
      child: EteeloBarRows(
        // La jauge est relative au n° 1.
        scale: EteeloBarRowsScale.byMax,
        rows: [
          for (var i = 0; i < articles.length; i++)
            EteeloBarRow(
              label: '${i + 1}. ${articles[i].label}',
              caption: [
                if (articles[i].family != null)
                  BoutiqueFamilyStyle.labelOf(articles[i].family, l10n),
                if (articles[i].amounts.isNotEmpty)
                  BoutiqueDashboardLabels.moneyInline(
                    articles[i].amounts.entries,
                  ),
              ].join(' · '),
              value: articles[i].quantity,
              valueLabel: l10n.boutiqueDashboardTopQuantity(
                articles[i].quantity,
              ),
              color: BoutiqueFamilyStyle.accentOf(articles[i].family),
              onTap: () => onArticleTap(articles[i]),
              semanticsLabel: l10n.boutiqueDashboardTopA11y(articles[i].label),
            ),
        ],
      ),
    );
  }
}
