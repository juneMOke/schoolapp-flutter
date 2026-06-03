import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_badge_builder.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SearchFormStatusFilterField extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String>? onChanged;

  const SearchFormStatusFilterField({
    super.key,
    required this.selectedStatus,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = buildEnrollmentStatusOptions(l10n);
    final selectItems = options
        .map(
          (option) => EteeloSelectItem<String>(
            value: option.value,
            label: option.label,
          ),
        )
        .toList(growable: false);
    final selectedValue =
        options.any((option) => option.value == selectedStatus)
        ? selectedStatus
        : options.first.value;

    return EteeloSelectInput<String>(
      label: l10n.enrollmentStatusFilterLabel,
      placeholder: l10n.selectPlaceholderChoose,
      value: selectedValue,
      items: selectItems,
      menuMaxHeight: 320,
      onChanged: (value) {
        if (value != null) {
          onChanged?.call(value);
        }
      },
      itemBuilder: (context, item, isSelected) => buildSearchFormStatusMenuItem(
        statusValue: item.value,
        label: item.label,
        l10n: l10n,
        isSelected: isSelected,
      ),
      selectedItemBuilder: (context, item) => buildSearchFormSelectedStatusItem(
        statusValue: item.value,
        label: item.label,
        l10n: l10n,
      ),
    );
  }
}
