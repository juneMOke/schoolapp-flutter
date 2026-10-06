import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre d'actions collante du détail (spec S7) : « x / n notes saisies » et
/// sa légende à gauche ; « Saisir les notes » puis [publishAction] à droite.
class EvalDetailActionBar extends StatelessWidget {
  final NotesProgress progress;
  final VoidCallback onSaisir;

  /// Légende sous le compteur (état de la publication des notes).
  final String? legend;

  /// Action de publication des notes, posée à droite de « Saisir ».
  final Widget? publishAction;

  const EvalDetailActionBar({
    super.key,
    required this.progress,
    required this.onSaisir,
    this.legend,
    this.publishAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.evalDetailNotesProgress(progress.saisies, progress.total),
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (legend != null)
                Text(
                  legend!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // La grille est nominative : elle exige le droit de lire les
              // notes (ADR-015 §6-B), comme la ligne du détail du cours.
              PermissionGate(
                requires: const [Perm.academicsGradeRead],
                child: EteeloButton.secondary(
                  label: progress.saisies == 0
                      ? l10n.evalDetailSaisirNotes
                      : l10n.evalDetailSaisieNotes,
                  icon: Icons.edit_outlined,
                  fullWidth: false,
                  onPressed: onSaisir,
                ),
              ),
              ?publishAction,
            ],
          ),
        ],
      ),
    );
  }
}
