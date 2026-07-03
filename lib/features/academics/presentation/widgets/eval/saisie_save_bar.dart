import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre d'enregistrement (spec §10) : compteur « x / n saisies », barre de
/// progression (verte, rouge si erreurs), alerte des notes hors bornes, et le
/// bouton « Enregistrer les notes » (désactivé si erreurs ou aucune modification).
class SaisieSaveBar extends StatelessWidget {
  final SaisieDraftController draft;
  final bool isSaving;
  final VoidCallback onSave;

  const SaisieSaveBar({
    super.key,
    required this.draft,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) {
        final total = draft.total;
        final entered = draft.enteredCount;
        final errors = draft.errorCount;
        final fraction = total == 0 ? 0.0 : entered / total;
        final canSave = !isSaving && errors == 0 && draft.dirty;

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
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.evalSaveCounter(entered, total),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ProgressBar(fraction: fraction, hasError: errors > 0),
                    if (errors > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.evalSaveErrorsAlert(errors),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.academicsScoreFail,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              EteeloButton.primary(
                label: isSaving
                    ? l10n.evalSaveButtonSaving
                    : l10n.evalSaveButton,
                icon: isSaving ? null : Icons.check_rounded,
                isLoading: isSaving,
                loadingLabel: l10n.evalSaveButtonSaving,
                size: EteeloButtonSize.regular,
                fullWidth: false,
                onPressed: canSave ? onSave : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double fraction;
  final bool hasError;

  const _ProgressBar({required this.fraction, required this.hasError});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.brPill,
      child: SizedBox(
        height: 6,
        child: ColoredBox(
          color: AppColors.surfaceAlt,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: ColoredBox(
              color: hasError
                  ? AppColors.academicsScoreFail
                  : AppColors.academicsScoreGood,
            ),
          ),
        ),
      ),
    );
  }
}
