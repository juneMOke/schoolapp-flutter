import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La carte d'enregistrement du barème (direction) : l'état de la saisie,
/// « Rétablir les valeurs par défaut » et « Enregistrer le barème », inactif
/// tant qu'un champ est en erreur ou que rien n'a changé.
class PayrollSettingsSaveBar extends StatelessWidget {
  final bool dirty;
  final bool hasErrors;
  final bool saving;

  /// Les paies encore à valider, que le barème enregistré recalculera.
  final int openPayrolls;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const PayrollSettingsSaveBar({
    super.key,
    required this.dirty,
    required this.hasErrors,
    required this.saving,
    required this.openPayrolls,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = hasErrors
        ? l10n.payrollSettingsStateErrors
        : dirty
        ? l10n.payrollSettingsStateDirty(openPayrolls)
        : l10n.payrollSettingsStateClean;
    final ink = hasErrors
        ? AppColors.error
        : dirty
        ? AppColors.staffPartialInk
        : AppColors.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            Text(message, style: AppTypography.labelLarge.copyWith(color: ink)),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                EteeloButton.ghost(
                  label: l10n.payrollSettingsReset,
                  onPressed: saving ? null : onReset,
                  fullWidth: false,
                ),
                EteeloButton.primary(
                  label: l10n.payrollSettingsSave,
                  isLoading: saving,
                  onPressed: dirty && !hasErrors && !saving ? onSave : null,
                  fullWidth: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
