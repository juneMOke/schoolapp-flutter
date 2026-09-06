import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_cycle_palette.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_who_sections.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Où » — dans quels niveaux les élèves de la fenêtre sont entrés.
///
/// ## Des lignes-barres, plus un anneau
///
/// L'écran affichait un donut : au-delà de cinq ou six parts, il devient une
/// légende que l'œil doit rapprocher de secteurs qu'il ne sait plus mesurer.
/// Une école aligne facilement une douzaine de niveaux.
///
/// **Les niveaux à zéro sont masqués** : une barre vide n'apprend rien et
/// allonge une liste déjà longue. Le sous-titre annonce donc combien de
/// niveaux sont réellement concernés — sinon l'absence d'un niveau se lirait
/// comme un oubli.
class EnrollmentLevelSection extends StatelessWidget {
  final CycleDistribution distribution;
  final bool isSingleDay;

  /// Ouvre Première inscription cadré sur un niveau. `null` rend les lignes
  /// non cliquables.
  final void Function(LevelStat level)? onLevelTap;

  /// Actions d'export, posées dans l'en-tête de la carte.
  ///
  /// **Elles disparaissent quand il n'y a rien à exporter** : un bouton PDF
  /// au-dessus d'une carte vide produirait un document d'une page blanche.
  final List<Widget> exportActions;

  const EnrollmentLevelSection({
    super.key,
    required this.distribution,
    required this.isSingleDay,
    this.onLevelTap,
    this.exportActions = const [],
  });

  /// Les niveaux affichés, pour un appelant qui doit montrer **la même
  /// chose** — l'export PDF.
  ///
  /// Exposé plutôt que recalculé de l'autre côté : un export qui re-trierait
  /// ou re-filtrerait serait un second écran à tenir d'accord avec le premier,
  /// et ils divergeraient au premier changement de règle.
  static List<LevelStat> levelsOf(CycleDistribution distribution) =>
      EnrollmentLevelSection(
        distribution: distribution,
        isSingleDay: false,
      )._levels;

  /// Les niveaux qui ont reçu au moins une inscription, du plus gros au plus
  /// petit.
  ///
  /// **Tri stable** : à effectif égal, l'ordre reçu du serveur — l'ordre
  /// pédagogique — départage. `List.sort` de Dart ne garantit PAS la
  /// stabilité, donc l'index d'origine est comparé explicitement ; sans lui,
  /// deux niveaux ex æquo pourraient permuter d'un rendu à l'autre, ce qui se
  /// lirait comme un mouvement d'effectif.
  List<LevelStat> get _levels {
    final levels = [
      for (final cycle in distribution.cycles)
        for (final level in cycle.levels)
          if (level.value > 0) level,
    ];
    final indexed = [for (var i = 0; i < levels.length; i++) (i, levels[i])]
      ..sort((a, b) {
        final byValue = b.$2.value.compareTo(a.$2.value);
        return byValue != 0 ? byValue : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levels = _levels;
    final cycleColors = _cycleColors();

    return EteeloStatsCard(
      title: l10n.enrollmentDashboardLevelTitle,
      subtitle: l10n.enrollmentDashboardLevelSubtitle(
        isSingleDay
            ? l10n.enrollmentDashboardLevelToday
            : l10n.enrollmentDashboardSubtitlePeriod,
      ),
      hint: levels.isEmpty
          ? null
          : l10n.enrollmentDashboardLevelCount(levels.length),
      // Rien à exporter, donc pas de boutons — cf. la note de classe.
      actions: levels.isEmpty ? const [] : exportActions,
      child: levels.isEmpty
          ? EnrollmentDashboardNote(text: l10n.enrollmentDashboardLevelEmpty)
          : EteeloBarRows(
              rows: [
                for (final level in levels)
                  EteeloBarRow(
                    label: level.displayLabel,
                    value: level.value,
                    valueLabel: l10n.enrollmentDashboardStudentsCount(
                      level.value,
                    ),
                    color: cycleColors[level.cycle] ?? AppColors.bleuArdoise,
                    onTap: onLevelTap == null ? null : () => onLevelTap!(level),
                  ),
              ],
            ),
    );
  }

  /// Une teinte par cycle, stable d'une fenêtre à l'autre.
  ///
  /// La couleur est décorative : chaque ligne écrit déjà son niveau et son
  /// effectif. Elle sert seulement à regrouper l'œil par cycle.
  Map<String, Color> _cycleColors() {
    final codes = distribution.cycles.map((c) => c.code).toList();
    return {
      for (var i = 0; i < codes.length; i++) codes[i]: cyclePaletteColor(i),
    };
  }
}

/// « Où », vu de plus haut : les cycles.
///
/// Même barre, pas d'export — un tableau de trois lignes ne se transporte pas
/// dans un PDF, il se lit sur place.
class EnrollmentCycleSection extends StatelessWidget {
  final CycleDistribution distribution;

  const EnrollmentCycleSection({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Tri stable, même raison qu'au-dessus : deux cycles ex æquo gardent
    // l'ordre reçu plutôt que de permuter d'un rendu à l'autre.
    final kept = [
      for (final cycle in distribution.cycles)
        if (cycle.total > 0) cycle,
    ];
    final indexed = [for (var i = 0; i < kept.length; i++) (i, kept[i])]
      ..sort((a, b) {
        final byTotal = b.$2.total.compareTo(a.$2.total);
        return byTotal != 0 ? byTotal : a.$1.compareTo(b.$1);
      });
    final cycles = [for (final entry in indexed) entry.$2];

    return EteeloStatsCard(
      title: l10n.enrollmentDashboardCycleTitle,
      child: cycles.isEmpty
          ? EnrollmentDashboardNote(text: l10n.enrollmentDashboardLevelEmpty)
          : EteeloBarRows(
              rows: [
                for (var i = 0; i < cycles.length; i++)
                  EteeloBarRow(
                    label: cycles[i].displayLabel,
                    value: cycles[i].total,
                    valueLabel: l10n.enrollmentDashboardStudentsCount(
                      cycles[i].total,
                    ),
                    color: cyclePaletteColor(i),
                  ),
              ],
            ),
    );
  }
}
