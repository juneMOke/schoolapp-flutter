import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_dashboard_format.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_who_sections.dart';
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
/// ## Le plancher d'axe est bas
///
/// [AppDimensions.enrollmentDashboardPaceMinTop] : le défaut du socle (10)
/// convient aux montants en centimes ; ici, une école qui inscrit un à trois
/// élèves par jour verrait toutes ses barres écrasées contre l'axe.
class EnrollmentPaceSection extends StatelessWidget {
  final EnrollmentEvolution evolution;

  const EnrollmentPaceSection({super.key, required this.evolution});

  /// Plancher de lisibilité de l'axe, en nombre de barres.
  ///
  /// Spec l.350 : « la barre doit rester lisible — jamais plus d'une trentaine
  /// de barres, **jamais moins de trois** ».
  static const int minVisibleBuckets = 3;

  /// Les buckets réellement portés à l'axe.
  ///
  /// ⚠️ **Écart assumé à la spec** (l.383 : « barres à 0 conservées — la trame
  /// de temps reste lisible ») : le porteur produit ne veut plus voir les jours
  /// sans données. La demande est appliquée, sous deux garde-fous :
  ///
  ///  * le bucket **en cours** reste, même à zéro — sinon la fenêtre
  ///    « Aujourd'hui » pourrait ne plus contenir aujourd'hui, et le relief
  ///    n'aurait plus de support ;
  ///  * **en dessous de trois barres, la fenêtre dense complète est rendue** :
  ///    filtrer peut ne laisser qu'une barre (fenêtre « Aujourd'hui » où seul
  ///    aujourd'hui compte une inscription), et une barre seule ne se lit pas
  ///    comme un rythme — c'est précisément ce que la série de cinq jours
  ///    existe pour éviter.
  ///
  /// Exposé et statique pour être éprouvé sans monter de widget.
  static List<EvolutionBucket> visibleBuckets(List<EvolutionBucket> buckets) {
    final kept = [
      for (final bucket in buckets)
        if (bucket.value > 0 || bucket.isCurrent) bucket,
    ];
    return kept.length < minVisibleBuckets ? buckets : kept;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buckets = evolution.buckets;

    // Rien de compté sur toute la fenêtre : un axe de barres à zéro n'apprend
    // rien qu'une phrase ne dise mieux.
    if (!buckets.any((bucket) => bucket.value > 0)) {
      return EteeloStatsCard(
        title: l10n.enrollmentDashboardPaceTitle,
        icon: Icons.bar_chart_outlined,
        child: EnrollmentDashboardNote(text: l10n.enrollmentDashboardPaceEmpty),
      );
    }

    final shown = visibleBuckets(buckets);

    final items = [
      for (final bucket in shown)
        BarChartItem(
          // Le libellé du serveur, tel quel.
          label: bucket.shortLabel,
          value: bucket.value.toDouble(),
          color: bucket.isCurrent
              ? AppColors.bleuArdoise
              : AppColors.enrollmentStatsPaceBar,
        ),
    ];

    final highlighted = <int>{
      for (var i = 0; i < shown.length; i++)
        if (shown[i].isCurrent) i,
    };

    return EteeloStatsCard(
      title: l10n.enrollmentDashboardPaceTitle,
      icon: Icons.bar_chart_outlined,
      child: Semantics(
        container: true,
        label: _a11yLabel(l10n, shown),
        child: ExcludeSemantics(
          child: CycleBarChart(
            items: items,
            highlightedIndexes: highlighted,
            showValueLabels: true,
            // Au-delà d'une douzaine de barres, les libellés horizontaux se
            // chevauchent : on les redresse plutôt que de les tronquer.
            verticalBottomLabels: items.length > 12,
            minTop: AppDimensions.enrollmentDashboardPaceMinTop,
            barRadius: AppDimensions.enrollmentStatsChartPaceBorderRadius,
            gridDivisions: AppDimensions.enrollmentStatsChartPaceGridDivisions,
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
