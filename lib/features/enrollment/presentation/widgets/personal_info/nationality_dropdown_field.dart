import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class NationalityDropdownField extends StatefulWidget {
  final double width;
  final String label;
  final String helpMessage;
  final List<String> options;
  final String? value;
  final String? errorText;
  final bool requiredField;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const NationalityDropdownField({
    super.key,
    required this.width,
    required this.label,
    required this.helpMessage,
    required this.options,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.requiredField = false,
    this.enabled = true,
  });

  @override
  State<NationalityDropdownField> createState() => _NationalityDropdownFieldState();
}

class _NationalityDropdownFieldState extends State<NationalityDropdownField> {
  late final SearchController _searchController;
  late final TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    _displayController = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant NationalityDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _displayController.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _displayController.dispose();
    super.dispose();
  }

  Iterable<String> _filteredOptions(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return widget.options;
    }
    return widget.options.where(
      (option) => option.toLowerCase().contains(normalizedQuery),
    );
  }

  void _onOptionSelected(String option) {
    _displayController.text = option;
    widget.onChanged(option);
    _searchController.closeView(option);
  }

  Widget _buildSuggestionTile(String option) {
    final isSelected = option == widget.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.public_rounded,
            size: 16,
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryColor,
          ),
          title: Text(
            option,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          onTap: () => _onOptionSelected(option),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(
            label: widget.label,
            requiredField: widget.requiredField,
            helpMessage: widget.helpMessage,
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              listTileTheme: const ListTileThemeData(
                iconColor: AppTheme.textSecondaryColor,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              dividerColor: AppTheme.primaryColor.withValues(alpha: 0.08),
            ),
            child: SearchAnchor(
              searchController: _searchController,
              isFullScreen: true,
              viewHintText: l10n.enterFieldHint(widget.label),
              builder: (context, controller) {
                return TextFormField(
                  controller: _displayController,
                  readOnly: true,
                  enabled: widget.enabled,
                  onTap: widget.enabled ? controller.openView : null,
                  decoration: buildInputDecoration(
                    hintText: l10n.enterFieldHint(widget.label),
                    errorText: widget.errorText,
                    prefixIcon: const Icon(
                      Icons.public_rounded,
                      size: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
              suggestionsBuilder: (context, controller) {
                return _filteredOptions(
                  controller.text,
                ).map((option) => _buildSuggestionTile(option));
              },
            ),
          ),
        ],
      ),
    );
  }
}
