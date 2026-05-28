import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/core/components/labels/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EditableField extends StatelessWidget {
  final double width;
  final String label;
  final TextEditingController controller;
  final TextCapitalization textCapitalization;
  final bool requiredField;
  final String helpMessage;
  final String? errorText;
  final bool isChanged;
  final bool readOnly;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  const EditableField({
    super.key,
    required this.width,
    required this.label,
    required this.controller,
    this.textCapitalization = TextCapitalization.words,
    this.requiredField = false,
    this.helpMessage = '',
    this.errorText,
    this.isChanged = false,
    this.readOnly = false,
    this.hintText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
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
            labelColor: isChanged ? AppColors.success : null,
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              final effectiveInputFormatters =
                  inputFormatters ??
                  const [FirstLetterUppercaseTextInputFormatter()];
              return TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                textCapitalization: textCapitalization,
                style: AppTypography.formValueMedium,
                inputFormatters: effectiveInputFormatters,
                readOnly: readOnly,
                decoration: buildInputDecoration(
                  hintText: hintText ?? l10n.enterFieldHint(label),
                  errorText: errorText,
                  isChanged: isChanged,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasText && !readOnly)
                        IconButton(
                          tooltip: l10n.clear,
                          onPressed: controller.clear,
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
