import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/labels/form_field_label.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ValidatedYearSelector extends StatelessWidget {
  final AppLocalizations l10n;
  final double width;
  final bool validatedPreviousYear;
  final ValueChanged<bool> onChanged;
  final bool isChanged;
  final bool enabled;
  final String helpMessage;

  const ValidatedYearSelector({
    super.key,
    required this.l10n,
    required this.width,
    required this.validatedPreviousYear,
    required this.onChanged,
    this.isChanged = false,
    this.enabled = true,
    this.helpMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(
            label: l10n.yearValidated,
            // Oui/Non = teinte neutre unique (bleu ardoise), pas de connotation.
            labelColor: isChanged ? AppColors.bleuArdoise : null,
            helpMessage: helpMessage,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.yearValidated),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.yearNotValidated),
                  icon: const Icon(Icons.cancel_rounded, size: 16),
                ),
              ],
              selected: {validatedPreviousYear},
              onSelectionChanged: enabled
                  ? (selection) {
                      final selectedValue = selection.firstOrNull;
                      if (selectedValue != null) {
                        onChanged(selectedValue);
                      }
                    }
                  : null,
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textSecondary,
                selectedForegroundColor: AppColors.textOnDark,
                selectedBackgroundColor: AppColors.bleuArdoise,
                side: BorderSide(
                  color: AppColors.bleuArdoise.withValues(alpha: 0.25),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brSm,
                ),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
