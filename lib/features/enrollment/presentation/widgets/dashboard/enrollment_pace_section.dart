import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_dashboard_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le rythme d'inscription — **quand** les élèves sont arrivés.
///
/// ## Le découpage est un fait serveur, pas un calcul d'écran
///
/// Le grain suit la fenêtre (jour, semaine, mois), la règle de tranchage vit
/// côté serveur, et **les libellés en découlent** : `shortLabel` pour l'axe,
/// `longLabel` pour l'infobulle. Ce widget ne dérive rien de la clé du bucket.
///
/// C'est la leçon d'un défaut réel : la version précédente reconstruisait le
/// libellé d'axe en découpant la clé (`"2026-03"` → `"03"`). Depuis que l'axe
/// replie ce qui déborde dans une barre `out-of-axis-before`, cette dérivation
/// afficherait « fore » sur l'axe. Une clé identifie une barre ; elle ne la
/// date pas.
///
/// ## Deux réglages qui ne vont pas de soi
///
/// * **Le plancher d'axe est bas** ([AppDimensions.enrollmentDashboardPaceMinTop]).
///   Le défaut du socle (10) convient aux montants en centimes ; ici, une
///   école qui inscrit un à trois élèves par jour verrait toutes ses barres
///   écrasées contre l'axe, tous les jours.
/// * **Les barres à zéro sont conservées.** Le serveur garantit une série
///   dense — un bucket par intervalle, valeur nulle comprise — et c'est ce qui
///   garde la trame de temps lisible : un jour creux se voit, il ne disparaît
///   pas de l'axe.
class EnrollmentPaceSection extends StatelessWidget {
  final EnrollmentEvolution evolution;

  const EnrollmentPaceSection({super.key, required this.evolution});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buckets = evolution.buckets;

    final items = [
      for (final bucket in buckets)
        BarChartItem(
          // Le libellé du serveur, tel quel.
          label: bucket.shortLabel,
          value: bucket.value.toDouble(),
          color: bucket.isCurrent
              ? AppColors.bleuArdoise
              : AppColors.enrollmentStatsPreSoft,
        ),
    ];

    final highlighted = <int>{
      for (var i = 0; i < buckets.length; i++)
        if (buckets[i].isCurrent) i,
    };

    return EteeloStatsCard(
      title: l10n.enrollmentDashboardPaceTitle,
      child: items.isEmpty
          ? const SizedBox.shrink()
          : Semantics(
              container: true,
              label: _a11yLabel(l10n, buckets),
              child: ExcludeSemantics(
                child: CycleBarChart(
                  items: items,
                  highlightedIndexes: highlighted,
                  showValueLabels: true,
                  // Au-delà d'une douzaine de barres, les libellés horizontaux
                  // se chevauchent : on les redresse plutôt que de les tronquer.
                  verticalBottomLabels: items.length > 12,
                  minTop: AppDimensions.enrollmentDashboardPaceMinTop,
                  valueLabelFormatter: (value) =>
                      EnrollmentDashboardFormat.count(value.round()),
                  valueLabelColorBuilder: (index) => highlighted.contains(index)
                      ? AppColors.bleuArdoise
                      : AppColors.textSecondary,
                ),
              ),
            ),
    );
  }

  /// La série, en toutes lettres — le seul équivalent textuel du tracé.
  ///
  /// Chaque barre y porte son libellé long et sa valeur accordée : « septembre
  /// 2026, 14 élèves ». Un lecteur d'écran n'a pas à deviner une hauteur.
  String _a11yLabel(AppLocalizations l10n, List<EvolutionBucket> buckets) {
    final parts = [
      for (final bucket in buckets)
        '${bucket.longLabel.isEmpty ? bucket.shortLabel : bucket.longLabel}, '
            '${l10n.enrollmentDashboardStudentsCount(bucket.value)}',
    ];
    return '${l10n.enrollmentDashboardPaceA11yLabel(buckets.length)}. '
        '${parts.join('. ')}';
  }
}
