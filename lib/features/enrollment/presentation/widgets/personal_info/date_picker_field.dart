import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DatePickerField extends StatelessWidget {
  final double width;
  final String label;
  final DateTime? selectedDate;
  final String displayValue;
  final bool requiredField;
  final String helpMessage;
  final VoidCallback onTap;
  final String? errorText;
  final bool enabled;

  const DatePickerField({
    super.key,
    required this.width,
    required this.label,
    required this.selectedDate,
    required this.displayValue,
    required this.onTap,
    this.requiredField = false,
    this.helpMessage = '',
    this.errorText,
    this.enabled = true,
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
          TextFormField(
            readOnly: true,
            enabled: enabled,
            onTap: enabled ? onTap : null,
            controller: TextEditingController(text: displayValue),
            decoration: buildInputDecoration(
              hintText: l10n.dateHint,
              errorText: errorText,
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              suffixIcon: GestureDetector(
                onTap: enabled ? onTap : null,
                child: const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
