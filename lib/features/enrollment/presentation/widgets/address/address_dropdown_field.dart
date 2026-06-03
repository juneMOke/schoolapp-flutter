import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

    final selectedValue = value != null && options.contains(value)
        ? value
        : null;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EteeloSelectInput<String>(
            value: selectedValue,
            label: label,
            required: requiredField,
            errorText: errorText,
            enabled: enabled && options.isNotEmpty,
            placeholder: l10n.selectPlaceholderChoose,
            menuMaxHeight: 320,
            items: options
                .map(
                  (option) =>
                      EteeloSelectItem<String>(value: option, label: option),
                )
                .toList(growable: false),
            onChanged: onChanged,
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
