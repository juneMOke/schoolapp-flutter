import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';

class DropdownField extends StatelessWidget {
  final double width;
  final String label;
  final String helpMessage;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String? value;
  final String? errorText;
  final bool isChanged;
  final bool enabled;

  const DropdownField({
    super.key,
    required this.width,
    required this.label,
    required this.helpMessage,
    required this.items,
    required this.onChanged,
    this.value,
    this.errorText,
    this.isChanged = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(
            label: label,
            helpMessage: helpMessage,
            labelColor: isChanged ? const Color(0xFF15803D) : null,
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            items: items,
            onChanged: (!enabled || items.isEmpty) ? null : onChanged,
            decoration: buildInputDecoration(
              hintText: label,
              isChanged: isChanged,
              prefixIcon: const Icon(
                Icons.arrow_drop_down_circle_outlined,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              errorText: errorText,
            ),
          ),
        ],
      ),
    );
  }
}
