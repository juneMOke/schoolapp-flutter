import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Toutes · À viser · Visée · Signalée — le filtre du **visa** des
/// déclarations (v3), à côté de celui de l'état. Choisir un visa ne garde
/// que des déclarations : une demande d'autorisation n'en a pas.
class ExpenseVisaFilter extends StatelessWidget {
  final ExpenseVisaStatus? selected;
  final ValueChanged<ExpenseVisaStatus?> onChanged;

  const ExpenseVisaFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.expenseVisaFilterTitle.toUpperCase(),
          style: AppTextStyles.tableHeader.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        SegmentedTabFilter<String>(
          semanticsLabel: l10n.expenseVisaFilterTitle,
          selected: selected?.wireValue ?? '',
          onSelected: (value) => onChanged(
            value.isEmpty
                ? null
                : ExpenseVisaStatus.fromWire(
                    value,
                    mode: ExpenseMode.declaration,
                  ),
          ),
          options: [
            SegmentedTabOption(label: l10n.expenseVisaFilterAll, value: ''),
            SegmentedTabOption(
              label: l10n.expenseVisaPending,
              value: ExpenseVisaStatus.pending.wireValue,
            ),
            SegmentedTabOption(
              label: l10n.expenseVisaVisaed,
              value: ExpenseVisaStatus.visaed.wireValue,
            ),
            SegmentedTabOption(
              label: l10n.expenseVisaFlagged,
              value: ExpenseVisaStatus.flagged.wireValue,
            ),
          ],
        ),
      ],
    );
  }
}
