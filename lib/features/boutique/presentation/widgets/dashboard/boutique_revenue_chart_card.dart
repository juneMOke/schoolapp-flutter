import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_labels.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/boutique_dashboard_tones.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/revenue_series.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Recettes jour par jour » / « heure par heure » / « mois par mois » —
/// quand on vend.
///
/// Le même graphique en barres que la caisse Finances : la barre en cours en
/// terre cuite **et** chiffrée (la couleur ne porte jamais seule
/// l'information), toutes chiffrées jusqu'à dix barres, aucun axe vertical.
/// La carte et les autres barres prennent la teinte de la devise affichée.
class BoutiqueRevenueChartCard extends StatelessWidget {
  final BoutiqueCurrencyStats block;
  final StatsGranularity granularity;

  /// La clé du seau en cours (aujourd'hui, ou l'heure qu'il est). Sur une
  /// série regroupée par mois, le mois de ce jour est en cours.
  final String currentKey;

  /// Le choix de devise, posé dans l'en-tête de la carte.
  final Widget? currencySelector;

  static const int _labelAllBarsUpTo = 10;
  static const int _rotateLabelsBeyond = 12;

  const BoutiqueRevenueChartCard({
    super.key,
    required this.block,
    required this.granularity,
    required this.currentKey,
    this.currencySelector,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthly = RevenueSeries.isMonthly(block.buckets, granularity);
    final title = granularity == StatsGranularity.hour
        ? l10n.boutiqueDashboardChartHourly
        : monthly
        ? l10n.boutiqueDashboardChartMonthly
        : l10n.boutiqueDashboardChartDaily;
    final visible = RevenueSeries.visible(block.buckets, granularity);
    final currentDay = monthly ? DateTime.tryParse(currentKey) : null;
    final current = RevenueSeries.currentIndex(
      visible,
      currentDay == null ? currentKey : RevenueSeries.monthKey(currentDay),
    );
    final labels = [
      for (final bucket in visible)
        BoutiqueDashboardLabels.bucketLabel(bucket, granularity, l10n),
    ];
    String money(num cents) =>
        MoneyFormat.compact(Money.parse(cents.round(), block.currency));
    final tone = BoutiqueDashboardTones.devise(block.currency);

    return EteeloStatsCard(
      title: title,
      subtitle: l10n.boutiqueDashboardChartSubtitle,
      icon: Icons.trending_up_rounded,
      tone: tone,
      toneStrength: BoutiqueDashboardTones.sectionStrength(tone),
      actions: [?currencySelector],
      child: visible.isEmpty
          ? const SizedBox.shrink()
          : Semantics(
              container: true,
              label: _summary(l10n, title, visible, labels, money),
              child: ExcludeSemantics(
                child: CycleBarChart(
                  items: [
                    for (var i = 0; i < visible.length; i++)
                      BarChartItem(
                        label: labels[i],
                        value: visible[i].total.toDouble(),
                        color: i == current ? AppColors.terreCuite : tone,
                      ),
                  ],
                  highlightedIndexes: {if (current >= 0) current},
                  showValueLabels: visible.length <= _labelAllBarsUpTo,
                  labelHighlightedBars: true,
                  verticalBottomLabels: visible.length > _rotateLabelsBeyond,
                  showLeftAxis: false,
                  gridDivisions: 2,
                  barRadius: 4,
                  minimumBarHeight: 2,
                  valueLabelFormatter: money,
                ),
              ),
            ),
    );
  }

  /// « Recettes jour par jour : 6 barres, maximum 238 $ (19/10) ».
  static String _summary(
    AppLocalizations l10n,
    String title,
    List<BoutiqueStatsBucket> visible,
    List<String> labels,
    String Function(num) money,
  ) {
    var peak = 0;
    for (var i = 1; i < visible.length; i++) {
      if (visible[i].total > visible[peak].total) peak = i;
    }
    return l10n.boutiqueDashboardChartA11y(
      title,
      visible.length,
      money(visible[peak].total),
      labels[peak],
    );
  }
}
