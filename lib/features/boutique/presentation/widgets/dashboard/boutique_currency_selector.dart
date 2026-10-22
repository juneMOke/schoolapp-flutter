import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix de la devise détaillée — **seulement** quand la fenêtre en a vendu
/// plusieurs. Une série ne mêle jamais dollars et francs.
class BoutiqueCurrencySelector extends StatelessWidget {
  final List<String> currencies;
  final String? selected;
  final ValueChanged<String> onSelected;

  const BoutiqueCurrencySelector({
    super.key,
    required this.currencies,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = this.selected;
    if (currencies.length < 2 || selected == null) {
      return const SizedBox.shrink();
    }
    return SegmentedTabFilter<String>(
      semanticsLabel: AppLocalizations.of(
        context,
      )!.boutiqueDashboardCurrencyA11y,
      selected: selected,
      onSelected: onSelected,
      options: [
        for (final currency in currencies)
          SegmentedTabOption(
            label: MoneyFormat.symbolOf(currency),
            value: currency,
          ),
      ],
    );
  }
}
