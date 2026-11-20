import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';

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

  /// Reliée, estompée ou normale (EDT §4.6 D).
  final SessionEmphasis emphasis;

  /// Un jour sans cours : la séance est barrée (EDT-R17).
  final bool struck;

  /// Une alerte (conflit, hors programme, refus) : fond rouge pâle, bord
  /// d'erreur, icône, et la raison en info-bulle.
  final String? alert;

  /// « En cours » : la séance du créneau actuel (R11).
  final String? badge;

  /// Survol ou focus : la séance repère son cours (I5).
  final ValueChanged<bool>? onHover;

  const ScheduleSessionChip({
    super.key,
    required this.cell,
    required this.visual,
    this.semanticsLabel,
    this.onTap,
    this.emphasis = SessionEmphasis.normal,
    this.struck = false,
    this.alert,
    this.badge,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final chip = _chip(context);
    final alert = this.alert;
    final framed = emphasis == SessionEmphasis.linked
        ? DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brSm,
              border: Border.all(
                color: visual.accent,
                width: AppDimensions.timetableLinkedRingWidth,
              ),
            ),
            child: chip,
          )
        : chip;
    final faded = Opacity(
      opacity: emphasis == SessionEmphasis.dimmed || struck
          ? AppDimensions.timetableDimmedOpacity
          : 1,
      child: framed,
    );
    // Le nom entier au survol (ou à l'appui long) : dans une case de la
    // grille, il est souvent tronqué (« Éducation phy… »). Le lecteur d'écran
    // a déjà le libellé composé.
    return Tooltip(
      message: [
        cell.subjectLabel,
        if (cell.classroomLabel.trim().isNotEmpty) cell.classroomLabel,
        ?alert,
      ].join(' · '),
      excludeFromSemantics: true,
      child: faded,
    );
  }

  Widget _chip(BuildContext context) {
    final alert = this.alert;
    final badge = this.badge;
    final hover = onHover;
    final soft = alert == null ? visual.soft : AppColors.feeStatusDueSoft;
    final edge = alert == null
        ? visual.accent.withValues(alpha: 0.25)
        : AppColors.error;
    final decoration = struck
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : const TextStyle();
    return Semantics(
      button: onTap != null,
      onTap: onTap,
      // Un seul nœud sémantique : exclut les Text descendants au profit du
      // libellé composé. onTap reporté ici pour rester activable au lecteur.
      excludeSemantics: true,
      label: [
        semanticsLabel ?? '${cell.subjectLabel} — ${cell.classroomLabel}',
        ?badge,
        ?alert,
      ].join(' · '),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onHover: hover,
          onFocusChange: hover,
          borderRadius: AppRadius.brSm,
          // Bord fin UNIFORME (contrainte Flutter : pas de bord non-uniforme
          // avec borderRadius) ; le liséré gauche est un bandeau clippé séparé.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: soft,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: edge),
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
                            Row(
                              children: [
                                if (alert != null) ...[
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: AppSpacing.md,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                Expanded(
                                  child: Text(
                                    cell.subjectLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelMedium
                                        .copyWith(
                                          color: visual.accent,
                                          fontWeight: FontWeight.w600,
                                        )
                                        .merge(decoration),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              cell.classroomLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall
                                  .copyWith(color: AppColors.textSecondary)
                                  .merge(decoration),
                            ),
                            if (badge != null)
                              Text(
                                badge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.terreCuite,
                                  fontWeight: FontWeight.w600,
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
