import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class GuardianPhoneField extends StatelessWidget {
  final double width;
  final String label;
  final String helpMessage;
  final TextEditingController controller;
  final bool requiredField;
  final bool isChanged;
  final bool readOnly;
  final String? errorText;

  const GuardianPhoneField({
    super.key,
    required this.width,
    required this.label,
    required this.helpMessage,
    required this.controller,
    this.requiredField = false,
    this.isChanged = false,
    this.readOnly = false,
    this.errorText,
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
            labelColor: isChanged ? const Color(0xFF15803D) : null,
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              return TextFormField(
                controller: controller,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9+()\- ]'),
                  ),
                ],
                readOnly: readOnly,
                decoration: buildInputDecoration(
                  hintText: l10n.phoneNumberHelp,
                  errorText: errorText,
                  isChanged: isChanged,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
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
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      Icon(
                        readOnly
                            ? Icons.lock_outline_rounded
                            : Icons.mode_edit_outline_rounded,
                        size: 16,
                        color: readOnly
                            ? AppTheme.textSecondaryColor
                            : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
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
