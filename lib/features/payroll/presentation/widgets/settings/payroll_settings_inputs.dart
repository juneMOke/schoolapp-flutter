import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_field_grid.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/settings/payroll_settings_field_error.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le message d'un champ du barème en erreur, ou `null`.
String? payrollSettingsErrorText(
  AppLocalizations l10n,
  PayrollSettingsFieldError? error,
) => switch (error) {
  null => null,
  PayrollSettingsOutOfRange(:final range) => l10n.payrollSettingsErrorRange(
    range.min,
    range.max,
  ),
  PayrollSettingsBadAmount() => l10n.payrollSettingsErrorAmount,
  PayrollSettingsBelowMin() => l10n.payrollSettingsErrorStep,
  PayrollSettingsLabelTooLong(:final max) => l10n.payrollSettingsErrorLabel(
    max,
  ),
};

/// Un champ numérique du barème, grisé en lecture seule.
class PayrollSettingsNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final PayrollSettingsFieldError? error;
  final bool readOnly;

  const PayrollSettingsNumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.error,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) => EteeloTextInput(
    controller: controller,
    label: label,
    keyboardType: EteeloTextInputType.number,
    capitalization: EteeloTextCapitalization.none,
    enabled: !readOnly,
    errorText: payrollSettingsErrorText(AppLocalizations.of(context)!, error),
  );
}

/// Une carte du barème : un titre, ce qu'elle règle, les champs en grille.
class PayrollSettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> fields;
  final Widget? footer;

  const PayrollSettingsCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fields,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: BiToneSectionCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfigurationFieldGrid(children: fields),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    ),
  );
}

/// Un réglage oui / non du barème : un interrupteur, son libellé à gauche —
/// comme les sections de frais de la Configuration. Toute la ligne bascule
/// (cible ≥ 48 dp) ; [onTap] nul, elle se lit sans se changer.
class PayrollSettingsToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const PayrollSettingsToggle({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.minTouchTarget,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: onTap == null
                      ? AppColors.textMutedAa
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Switch(
              value: selected,
              onChanged: onTap == null ? null : (_) => onTap!(),
            ),
          ],
        ),
      ),
    ),
  );
}
