import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EditableField extends StatelessWidget {
  final double width;
  final String label;
  final TextEditingController controller;
  final bool requiredField;
  final String helpMessage;

  const EditableField({
    super.key,
    required this.width,
    required this.label,
    required this.controller,
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
          TextFormField(
            controller: controller,
            textInputAction: TextInputAction.next,
            decoration: buildInputDecoration(
              hintText: l10n.enterFieldHint(label),
              prefixIcon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              suffixIcon: const Icon(
                Icons.mode_edit_outline_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}