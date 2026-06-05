import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';

class NationalityDropdownField extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final String? errorText;
  final bool requiredField;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const NationalityDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.requiredField = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return EteeloSelectInput<String>(
      label: label,
      value: value,
      enabled: enabled,
      required: requiredField,
      errorText: errorText,
      onChanged: onChanged,
      items: options
          .map(
            (option) => EteeloSelectItem<String>(value: option, label: option),
          )
          .toList(growable: false),
    );
  }
}
