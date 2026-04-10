import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ReadOnlyField extends StatelessWidget {
  final double width;
  final String label;
  final TextEditingController controller;
  final String helpMessage;
  final bool requiredField;

  const ReadOnlyField({
    super.key,
    required this.width,
    required this.label,
    required this.controller,
    required this.helpMessage,
    this.requiredField = false,
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
            readOnly: true,
            decoration: buildInputDecoration(
              hintText: l10n.enterFieldHint(label),
              prefixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
