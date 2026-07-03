import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';

/// Puce de séance de la grille (spec §4, variante compacte) : bloc aux couleurs
/// de la **classe** (fond doux, liséré gauche 3 px, bord fin). Ligne 1 = branche
/// (matière), ligne 2 = classe. La salle n'apparaît pas en grille (elle est
/// affichée par la rangée de la vue Jour). Cliquable → ouvre le cours (§7).
class ScheduleSessionChip extends StatelessWidget {
  final TimetableCell cell;
  final AcademicsClassVisual visual;

  /// Libellé lecteur d'écran (ex. jour · heure · branche · classe). Repli sur
  /// « branche — classe » si absent.
  final String? semanticsLabel;

  final VoidCallback? onTap;

  const ScheduleSessionChip({
    super.key,
    required this.cell,
    required this.visual,
    this.semanticsLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      // Un seul nœud sémantique : exclut les Text descendants au profit du
      // libellé composé. onTap reporté ici pour rester activable au lecteur.
      excludeSemantics: true,
      label: semanticsLabel ?? '${cell.subjectLabel} — ${cell.classroomLabel}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brSm,
          // Bord fin UNIFORME (contrainte Flutter : pas de bord non-uniforme
          // avec borderRadius) ; le liséré gauche est un bandeau clippé séparé.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: visual.soft,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: visual.accent.withValues(alpha: 0.25)),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.brSm,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3, color: visual.accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cell.subjectLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMedium.copyWith(
                                color: visual.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              cell.classroomLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
