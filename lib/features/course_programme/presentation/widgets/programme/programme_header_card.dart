import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/common/accent_edge_card.dart';
import 'package:school_app_flutter/features/course_programme/domain/services/programme_stats.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête « Programme du cours » (spec §2) : médaillon de la classe, branche
/// et classe, puces (chapitres · séances prévues · évaluations), bloc
/// d'avancement. Sous ~560 dp, l'avancement passe sous le titre.
class ProgrammeHeaderCard extends StatelessWidget {
  final CoursDetailArgs cours;
  final ProgrammeStats stats;
  final int evaluationsCount;

  const ProgrammeHeaderCard({
    super.key,
    required this.cours,
    required this.stats,
    required this.evaluationsCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AccentEdgeCard(
      accent: cours.visual.accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = _Identity(cours: cours);
          final chips = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              EteeloChip(label: l10n.programmeChapitresCount(stats.total)),
              EteeloChip(label: l10n.programmeSeancesCount(stats.seances)),
              EteeloChip(
                label: l10n.programmeEvaluationsCount(evaluationsCount),
              ),
            ],
          );
          final progress = ProgrammeProgress(stats: stats);
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: AppSpacing.md),
              chips,
            ],
          );
          if (constraints.maxWidth < ProgrammeLayout.progressWrapBelow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: AppSpacing.lg),
                progress,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(width: ProgrammeLayout.progressWidth, child: progress),
            ],
          );
        },
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final CoursDetailArgs cours;

  const _Identity({required this.cours});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: ProgrammeLayout.headerMedallion,
          height: ProgrammeLayout.headerMedallion,
          decoration: BoxDecoration(
            color: cours.visual.soft,
            borderRadius: AppRadius.brLg,
          ),
          child: Icon(
            Icons.layers_outlined,
            size: ProgrammeLayout.headerMedallionIcon,
            color: cours.visual.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  cours.brancheNom,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                cours.classroomName,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le bloc « Avancement du programme » : pourcentage des chapitres terminés,
/// barre verte, et le détail « N en cours · M à venir » quand un chapitre est
/// en cours.
class ProgrammeProgress extends StatelessWidget {
  final ProgrammeStats stats;

  const ProgrammeProgress({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.programmeProgressA11y(stats.percent),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.programmeProgressTitle,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${stats.percent} %',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.programmeTermine,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    l10n.programmeProgressDone(stats.termines, stats.total),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: stats.total == 0 ? 0 : stats.termines / stats.total,
                minHeight: ProgrammeLayout.progressBarHeight,
                color: AppColors.programmeTermine,
                backgroundColor: AppColors.programmeTermineSoft,
              ),
            ),
            if (stats.enCours > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.programmeProgressDetail(stats.enCours, stats.planifies),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
