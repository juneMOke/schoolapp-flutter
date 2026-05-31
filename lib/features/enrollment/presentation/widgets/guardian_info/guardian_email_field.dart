import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/components/labels/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianEmailField extends StatelessWidget {
  final double width;
  final String label;
  final String helpMessage;
  final TextEditingController controller;
  final bool requiredField;
  final bool isChanged;
  final bool readOnly;
  final String? errorText;
  final String? trailingLabel;

  const GuardianEmailField({
    super.key,
    required this.width,
    required this.label,
    required this.helpMessage,
    required this.controller,
    this.requiredField = false,
    this.isChanged = false,
    this.readOnly = false,
    this.errorText,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FormFieldLabel(
                  label: label,
                  requiredField: requiredField,
                  helpMessage: helpMessage,
                  labelColor: isChanged ? AppColors.success : null,
                ),
              ),
              if (trailingLabel != null && trailingLabel!.trim().isNotEmpty)
                Text(
                  trailingLabel!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              return TextFormField(
                controller: controller,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: AppTypography.formValueMedium,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                readOnly: readOnly,
                decoration: buildInputDecoration(
                  hintText: l10n.emailLabelHelp,
                  errorText: errorText,
                  isChanged: isChanged,
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
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
