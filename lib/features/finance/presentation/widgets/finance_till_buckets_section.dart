import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
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

  /// La devise de la caisse dessinée — elle habille les montants posés sur les
  /// barres. **Aucun nombre nu** : la doctrine vaut aussi sur un graphique.
  final String currency;

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

  /// Jusqu'à dix barres, **chacune porte son montant**. Au-delà, les étiquettes
  /// se marchent dessus et seule la barre en relief garde la sienne — que le
  /// composant du socle affiche via son infobulle.
  static const int _labelAllBarsUpTo = 10;

  const FinanceTillBucketsSection({
    super.key,
    required this.buckets,
    this.title,
    this.windowNote,
    this.granularity = '',
    this.currency = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final heading = title ?? l10n.financeTillSectionBuckets;

    // ⚠️ **Arbitrage du porteur, CONTRE la spec.** La spec écrit « un point par
    // jour civil, **y compris les jours à 0 — les trous sont l'information** »,
    // et le service back documente la même règle. Le porteur a tranché
    // l'inverse après avoir vu l'écran ; sa décision prime, et ce n'est pas une
    // lecture de la spec.
    //
    // Conséquence à connaître : l'axe cesse d'être régulier dans le temps. Deux
    // barres voisines peuvent être séparées d'un jour ou de six sans que rien
    // ne le dise, et une semaine creuse ressemble à une semaine pleine.
    final drawn = buckets.where((bucket) => bucket.total > 0).toList();

    // Une fenêtre entièrement creuse ne dessine plus **aucune** barre depuis cet
    // arbitrage : sans ce cas, le graphique rendrait un axe sans contenu là où
    // il rendait auparavant une rangée de zéros. C'est l'état vide qui parle.
    if (drawn.isEmpty) {
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
      for (final bucket in drawn)
        BarChartItem(
          label: shortBucketLabel(bucket.key, granularity: granularity),
          value: bucket.total.toDouble(),
          color: bucket.isCurrent
              ? AppColors.terreCuite
              : AppColors.bleuArdoise,
        ),
    ];

    final highlighted = <int>{
      for (var i = 0; i < drawn.length; i++)
        if (drawn[i].isCurrent) i,
    };

    // La règle de la spec, telle quelle : le montant est posé **sur** la barre
    // — jamais sur un axe vertical, qu'il n'y a pas — et sur toutes les barres
    // dès que la série en compte dix ou moins. Une fenêtre `jour` en a sept :
    // elles sont donc toutes chiffrées.
    // Le seuil porte sur la série **effectivement dessinée**, donc sur les
    // barres non nulles — la spec a toujours compté la série et non la fenêtre.
    // Un mois creux passera donc sous le seuil et portera ses montants, un mois
    // chargé non : ce n'est pas une irrégularité, c'est la même règle appliquée
    // à ce qu'on voit.
    final labelEveryBar = drawn.length <= _labelAllBarsUpTo;

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
              verticalBottomLabels: drawn.length > _rotateLabelsBeyond,
              showValueLabels: labelEveryBar,
              // ⚠️ **Au-delà du seuil, l'intervalle en cours garde son
              // montant.** Sans axe vertical et sans étiquettes, son relief ne
              // reposerait plus que sur la couleur — et la doctrine de cet
              // écran est qu'une couleur ne porte jamais seule une information.
              // La spec le dit d'ailleurs mot pour mot : « le jour en relief
              // est doublé d'une couleur ET d'une étiquette de montant ».
              labelHighlightedBars: true,
              // ⚠️ **Pas d'axe vertical, à aucun grain** — la spec n'en dessine
              // aucun, et le porteur l'a tranché en connaissant le prix : sur
              // une fenêtre large, où les barres ne portent pas leur montant,
              // le graphique devient une **forme**. Les trois lignes de grille
              // tiennent lieu d'échelle, et les chiffres se lisent dans les
              // tuiles et la table.
              //
              // L'option écartée — masquer l'axe seulement quand les montants
              // sont sur les barres — aurait rendu le graphique différent selon
              // le grain, ce qu'on venait justement de corriger.
              showLeftAxis: false,
              // Trois lignes de grille (0 / 50 / 100 %). Le composant compte
              // les **intervalles**, et il y a une ligne de plus qu'eux : deux
              // intervalles font donc les trois lignes de la spec.
              gridDivisions: 2,
              barRadius: 4,
              // Sans plancher, une journée à 300 FC sous un maximum à 9 000 000
              // rend une barre d'un demi-pixel — indiscernable d'un zéro. Et
              // comme les barres nulles ne se dessinent plus, une barre non
              // nulle invisible se lirait comme un **jour supprimé**.
              minimumBarHeight: 2,
              // `finFmtShort` : la forme abrégée est **réservée** aux
              // étiquettes de graphique, là où le montant entier ne tient pas.
              // Elle porte quand même son symbole.
              valueLabelFormatter: (value) =>
                  MoneyFormat.compact(Money.parse(value.round(), currency)),
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
    // « sem. 12/05 » : la barre couvre sept jours **à partir** de cette date,
    // et l'étiquette doit dire les deux — qu'il s'agit d'une semaine, et de
    // laquelle.
    'week' when parts.length == 3 => 'sem. ${parts[2]}/${parts[1]}',
    'month' when parts.length >= 2 => '${parts[1]}/${parts[0].substring(2)}',
    'day' when parts.length == 3 => '${parts[2]}/${parts[1]}',
    // Sans grain annoncé, la forme de la clé décide — l'ancien comportement.
    _ => switch (parts.length) {
      // `2026-05-15` → « 15/05 » : le jour SEUL laissait deviner le mois, et
      // une fenêtre libre peut enjamber deux mois.
      3 => '${parts[2]}/${parts[1]}',
      // `2026-05` → « 05/26 » : le mois et son millésime, l'axe annuel pouvant
      // enjamber deux années scolaires.
      2 => '${parts[1]}/${parts[0].substring(2)}',
      _ => key,
    },
  };
}
