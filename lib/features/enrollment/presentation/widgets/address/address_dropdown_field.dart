import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';

class AddressDropdownField extends StatelessWidget {
  final double width;
  final String label;
  final String helpMessage;
  final List<String> options;
  final String? value;
  final String? errorText;
  final bool requiredField;
  final bool enabled;
  final IconData icon;
  final String? emptyOptionsHint;
  final ValueChanged<String?> onChanged;

  const AddressDropdownField({
    super.key,
    required this.width,
    required this.label,
    required this.helpMessage,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.emptyOptionsHint,
    this.errorText,
    this.requiredField = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = value != null && options.contains(value)
        ? value
        : null;

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
          DropdownButtonFormField<String>(
            initialValue: selectedValue,
            isExpanded: true,
            menuMaxHeight: 320,
            borderRadius: BorderRadius.circular(12),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.primaryColor,
            ),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (!enabled || options.isEmpty) ? null : onChanged,
            decoration: buildInputDecoration(
              hintText: label,
              errorText: errorText,
              prefixIcon: Icon(
                icon,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          if (enabled && options.isEmpty && emptyOptionsHint != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    emptyOptionsHint!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
