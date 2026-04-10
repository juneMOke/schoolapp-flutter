import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GenderSegmentedField extends StatelessWidget {
  final double width;
  final String label;
  final Gender selectedGender;
  final bool requiredField;
  final String helpMessage;
  final ValueChanged<Gender?> onChanged;

  const GenderSegmentedField({
    super.key,
    required this.width,
    required this.label,
    required this.selectedGender,
    required this.onChanged,
    this.requiredField = false,
    this.helpMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(
            label: label,
            requiredField: requiredField,
            helpMessage: helpMessage,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Gender>(
              segments: [
                ButtonSegment<Gender>(
                  value: Gender.male,
                  label: Text(l10n.genderMale),
                  icon: const Icon(Icons.male_rounded, size: 16),
                ),
                ButtonSegment<Gender>(
                  value: Gender.female,
                  label: Text(l10n.genderFemale),
                  icon: const Icon(Icons.female_rounded, size: 16),
                ),
              ],
              selected: {selectedGender},
              onSelectionChanged: (selection) => onChanged(selection.firstOrNull),
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.textSecondaryColor,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: AppTheme.primaryColor,
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.25),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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