import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'axe du temps de la caisse — **le total, et lui seul**.
///
/// Les barres ne ventilent pas frais et boutique. Ce n'est pas une économie de
/// place : la ventilation se lit sur le résumé, une fois, là où on la cherche.
/// Le serveur a fait le même arbitrage pour lui-même en refusant de répliquer
/// ses postes sur chacune des trente-et-une barres d'un mois.
class FinanceTillBucketsSection extends StatelessWidget {
  final List<TillBucket> buckets;

  /// Le titre de la carte — il **nomme la caisse dessinée**. La série est
  /// mono-devise et n'est jamais convertie ; sans le nom, deux bascules plus
  /// tard on ne sait plus quelle caisse on regarde.
  final String? title;

  /// La phrase qui explique pourquoi le total des tuiles ne vaut pas la somme
  /// des barres — rendue **là où l'écart se voit**, et seulement sur la fenêtre
  /// où il existe.
  ///
  /// C'est une **propriété** de l'écran, pas une excuse : les tuiles comptent la
  /// fenêtre demandée, la série dessine ce qu'il faut pour la lire. Dite
  /// ailleurs — ou pas dite du tout — l'écart se fait passer pour un bug, et
  /// quelqu'un finit par « corriger » l'un des deux chiffres.
  final String? windowNote;

  /// Au-delà de douze compartiments, les libellés se chevauchent : un mois de
  /// trente-et-un jours est le pire cas que l'écran ait à dessiner.
  static const int _rotateLabelsBeyond = 12;

  const FinanceTillBucketsSection({
    super.key,
    required this.buckets,
    this.title,
    this.windowNote,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final heading = title ?? l10n.financeTillSectionBuckets;

    if (buckets.isEmpty) {
      return FinanceStatsChartCard(
        title: heading,
        child: FinanceStatsEmptyState(
          message: l10n.financeStatsNoData,
          hint: l10n.financeStatsNoDataHint,
          semanticLabel: l10n.financeStatsEmptyA11yLabel,
        ),
      );
    }

    final items = [
      for (final bucket in buckets)
        BarChartItem(
          label: shortBucketLabel(bucket.key),
          value: bucket.total.toDouble(),
          color: bucket.isCurrent
              ? AppColors.terreCuite
              : AppColors.bleuArdoise,
        ),
    ];

    final highlighted = <int>{
      for (var i = 0; i < buckets.length; i++)
        if (buckets[i].isCurrent) i,
    };

    return FinanceStatsChartCard(
      title: heading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: l10n.financeTillBucketsChartA11yLabel,
            child: CycleBarChart(
              items: items,
              highlightedIndexes: highlighted,
              verticalBottomLabels: buckets.length > _rotateLabelsBeyond,
            ),
          ),
          if (windowNote != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              windowNote!,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le libellé sous une barre, **par grain d'axe**.
///
/// Deux formes de clé descendent du serveur, et une seule règle ne peut pas les
/// couvrir : `YYYY-MM-DD` sur les axes de journées (jour, semaine, mois),
/// `YYYY-MM` sur l'axe annuel. Le formatteur du recouvrement, écrit pour l'axe
/// mensuel seul, rendait `5-15` sur une clé journalière — il coupait les quatre
/// derniers caractères d'une chaîne qui en compte dix.
String shortBucketLabel(String key) {
  final parts = key.split('-');
  return switch (parts.length) {
    // `2026-05-15` → « 15 » : le jour suffit, le mois est dans la fenêtre.
    3 => parts[2],
    // `2026-05` → « 05 » : le rang du mois, comme sur l'axe du recouvrement.
    2 => parts[1],
    _ => key,
  };
}
