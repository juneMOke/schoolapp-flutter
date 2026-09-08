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

  /// Le grain annoncé par le serveur — il décide de l'étiquette sous chaque
  /// barre. Voir [shortBucketLabel] : la forme de la clé ne suffit pas.
  final String granularity;

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
    this.granularity = '',
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
          label: shortBucketLabel(bucket.key, granularity: granularity),
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

/// Le libellé sous une barre, **selon le grain que le serveur annonce**.
///
/// ⚠️ **La forme de la clé ne suffit pas à décider.** Une tranche hebdomadaire
/// porte `2026-05-12` — la date de son premier jour —, exactement la forme
/// d'une journée. Étiqueter « 12 » ferait lire **sept jours d'encaissements
/// comme la journée du 12**, sur l'écran dont toute la doctrine est de ne
/// jamais laisser un chiffre se faire passer pour un autre.
///
/// [granularity] vient donc de la réponse (`day` / `week` / `month`), et n'est
/// **jamais redérivé** de la largeur de la fenêtre : le seuil qui décide du
/// grain appartient au serveur, et le dupliquer ici en ferait un nombre magique
/// qui divergerait en silence le jour où il bouge.
///
/// Vide — un serveur qui ne sert pas encore le champ — retombe sur la forme de
/// la clé, ce que faisait le formatteur avant lui.
String shortBucketLabel(String key, {String granularity = ''}) {
  final parts = key.split('-');

  return switch (granularity) {
    // « sem. 12 » : la barre couvre sept jours à partir de ce jour-là, et
    // l'étiquette doit le dire.
    'week' when parts.length == 3 => 'sem. ${parts[2]}',
    'month' when parts.length >= 2 => parts[1],
    'day' when parts.length == 3 => parts[2],
    // Sans grain annoncé, la forme de la clé décide — l'ancien comportement.
    _ => switch (parts.length) {
      // `2026-05-15` → « 15 » : le jour suffit, le mois est dans la fenêtre.
      3 => parts[2],
      // `2026-05` → « 05 » : le rang du mois, comme sur l'axe du recouvrement.
      2 => parts[1],
      _ => key,
    },
  };
}
