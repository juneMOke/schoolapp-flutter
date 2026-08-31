import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_counter.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/cycle_accents.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte d'un cycle : son en-tête, son réglage global, et ses niveaux.
///
/// **Trois familles de rendu**, décidées sur le nombre de barèmes servis — pas
/// sur une règle écrite ici :
/// - un barème sans filière → tronc commun, compteur simple ;
/// - plusieurs barèmes → une ligne par filière, un compteur par ligne, le
///   compteur simple étant refusé par le serveur ;
/// - aucun barème → compteur simple, plus un avertissement ambre.
class ConfigurationCycleCard extends StatelessWidget {
  final CatalogCycle cycle;
  final StructureSelection selection;
  final ValueChanged<StructureSelection> onChanged;

  const ConfigurationCycleCard({
    super.key,
    required this.cycle,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = cycleAccentOf(cycle.code);
    final open = selection.isCycleOpen(cycle);

    return Opacity(
      // Un cycle décoché s'estompe sans disparaître : il doit rester évident
      // qu'on peut le rouvrir.
      opacity: open ? 1 : 0.72,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brCard,
          border: Border.all(
            color: open
                ? accent.color.withValues(alpha: 0.23)
                : AppColors.border,
          ),
          boxShadow: open ? AppElevation.shadowCard : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              cycle: cycle,
              selection: selection,
              accent: accent,
              open: open,
              onToggle: (checked) =>
                  onChanged(selection.withCycleChecked(cycle, checked)),
              onDefaultChanged: (value) =>
                  onChanged(selection.withCycleDefault(cycle, value)),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    for (final level in cycle.levels)
                      _LevelRow(
                        level: level,
                        selection: selection,
                        accent: accent,
                        onChanged: onChanged,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CatalogCycle cycle;
  final StructureSelection selection;
  final CycleAccent accent;
  final bool open;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onDefaultChanged;

  const _Header({
    required this.cycle,
    required this.selection,
    required this.accent,
    required this.open,
    required this.onToggle,
    required this.onDefaultChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Un cycle dont AUCUN niveau n'est de tronc commun n'a pas de réglage
    // global à proposer : l'afficher inerte inviterait à chercher pourquoi il
    // ne fait rien.
    final hasPlainLevels = cycle.levels.any(
      (level) => !level.hasMultipleSections,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.surface,
        borderRadius: const BorderRadius.vertical(top: AppRadius.card),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(value: open, onChanged: (v) => onToggle(v ?? false)),
              const SizedBox(width: AppSpacing.xs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // `cycle.name` tel qu'il est servi : « Cycle Terminal de
                  // l'Éducation de Base », jamais « Secondaire — CTEB », qui
                  // n'existe pas au catalogue.
                  Text(
                    cycle.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    open
                        ? l10n.configurationCycleSummary(
                            selection.openLevelsOf(cycle),
                            cycle.levels.length,
                            selection.classroomsOfCycle(cycle),
                          )
                        : l10n.configurationCycleNotOffered,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (open && hasPlainLevels)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.configurationCycleClassroomsPerLevel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ConfigurationCounter(
                  value: selection.cycleDefaultOf(cycle),
                  accentColor: accent.color,
                  onChanged: onDefaultChanged,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final CatalogLevel level;
  final StructureSelection selection;
  final CycleAccent accent;
  final ValueChanged<StructureSelection> onChanged;

  const _LevelRow({
    required this.level,
    required this.selection,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final open = selection.isLevelOpen(level);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                value: open,
                // Cocher = rétablir la proposition du catalogue, décocher = 0.
                // La case et le compteur sont deux vues du même nombre.
                onChanged: (checked) => onChanged(
                  selection.withLevelChecked(level, checked ?? false),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(level.name, style: AppTypography.labelLarge),
                    if (!open)
                      Text(
                        l10n.configurationLevelNotOffered,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              // Le compteur simple n'existe QUE sur un niveau à barème unique
              // ou sans barème : sur un niveau à filières, il est refusé par le
              // serveur, et la rangée de filières le remplace.
              if (!level.hasMultipleSections)
                ConfigurationCounter(
                  value: selection.countFor(
                    StructureSelection.levelKey(level.code),
                  ),
                  accentColor: accent.color,
                  onChanged: (value) => onChanged(
                    selection.withCount(
                      StructureSelection.levelKey(level.code),
                      value,
                    ),
                  ),
                ),
            ],
          ),
          if (level.hasMultipleSections)
            _SectionRows(
              level: level,
              selection: selection,
              accent: accent,
              onChanged: onChanged,
            ),
          if (level.hasNoOfficialGrid && open)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xxl,
                top: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      // Un avertissement, pas un blocage : les classes se
                      // créent, l'étape reste valide.
                      l10n.configurationLevelNoGrid,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Une ligne par barème servi — jamais un produit cartésien du cycle.
class _SectionRows extends StatelessWidget {
  final CatalogLevel level;
  final StructureSelection selection;
  final CycleAccent accent;
  final ValueChanged<StructureSelection> onChanged;

  const _SectionRows({
    required this.level,
    required this.selection,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xxl, top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.configurationSectionsServed(level.name),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final section in level.sections)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Le libellé servi, et le code officiel du document
                        // papier : ne pas réécrire « Scientifique / Littéraire
                        // / Commerciale », ces libellés-là ne correspondent pas
                        // à ce qui est servi.
                        Text(section.libelle, style: AppTypography.bodyMedium),
                        Text(
                          '${section.codeOfficiel} · '
                          '${l10n.configurationSectionCourses(section.courseCount)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConfigurationCounter(
                    value: selection.countFor(
                      StructureSelection.sectionKey(
                        level.code,
                        section.officialCode,
                      ),
                    ),
                    accentColor: accent.color,
                    onChanged: (value) => onChanged(
                      selection.withCount(
                        StructureSelection.sectionKey(
                          level.code,
                          section.officialCode,
                        ),
                        value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
