import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_type_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Type + date de la dépense. La date est plafonnée à aujourd'hui (A8) : la
/// navigation ne va jamais dans le futur, une dépense datée de demain serait
/// invisible.
class ExpenseTypeDateFields extends StatelessWidget {
  final List<ExpenseType> types;
  final String typeId;
  final DateTime date;
  final DateTime today;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<DateTime?> onDateChanged;

  const ExpenseTypeDateFields({
    super.key,
    required this.types,
    required this.typeId,
    required this.date,
    required this.today,
    required this.onTypeChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingM,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.expenseFormTypeMinWidth,
            maxWidth: AppDimensions.expenseFormTypeMaxWidth,
          ),
          child: EteeloSelectInput<String>(
            label: l10n.expenseFormType,
            required: true,
            value: typeId.isEmpty ? null : typeId,
            onChanged: onTypeChanged,
            items: [
              for (final type in types)
                EteeloSelectItem(
                  value: type.id,
                  label: type.label,
                  icon: ExpenseTypeVisuals.icon(type.icon),
                ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.expenseFormDateMinWidth,
            maxWidth: AppDimensions.expenseFormDateMaxWidth,
          ),
          child: EteeloDateInput(
            label: l10n.expenseFormDate,
            required: true,
            value: date,
            onChanged: onDateChanged,
            firstDate: DateTime(today.year - 10),
            lastDate: today,
          ),
        ),
      ],
    );
  }
}

/// Devise d'engagement : proposée par le type, modifiable — un défaut
/// intelligent, pas une contrainte.
class ExpenseCurrencyField extends StatelessWidget {
  final List<String> currencies;
  final String selected;
  final ValueChanged<String> onChanged;

  const ExpenseCurrencyField({
    super.key,
    required this.currencies,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ExpenseLabelled(
      label: l10n.expenseFormCurrency,
      child: SegmentedTabFilter<String>(
        semanticsLabel: l10n.expenseFormCurrency,
        selected: selected,
        onSelected: onChanged,
        options: [
          for (final code in currencies)
            SegmentedTabOption(
              label: '${MoneyFormat.symbolOf(code)} $code',
              value: code,
            ),
        ],
      ),
    );
  }
}

/// Statut + source de fonds.
class ExpenseStatusFundingFields extends StatelessWidget {
  final ExpenseStatus status;
  final ExpenseFundingSource funding;
  final ValueChanged<ExpenseStatus> onStatusChanged;
  final ValueChanged<ExpenseFundingSource?> onFundingChanged;

  const ExpenseStatusFundingFields({
    super.key,
    required this.status,
    required this.funding,
    required this.onStatusChanged,
    required this.onFundingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingM,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        ExpenseLabelled(
          label: l10n.expenseStatusTitle,
          child: SegmentedTabFilter<ExpenseStatus>(
            semanticsLabel: l10n.expenseStatusTitle,
            selected: status,
            onSelected: onStatusChanged,
            options: [
              for (final value in ExpenseStatus.values)
                SegmentedTabOption(
                  label: expenseStatusLabel(l10n, value),
                  value: value,
                ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.expenseFormFundingMinWidth,
            maxWidth: AppDimensions.expenseFormFundingMaxWidth,
          ),
          child: EteeloSelectInput<ExpenseFundingSource>(
            label: l10n.expenseFormFunding,
            value: funding,
            onChanged: onFundingChanged,
            items: [
              for (final source in ExpenseFundingSource.values)
                EteeloSelectItem(
                  value: source,
                  label: expenseFundingLabel(l10n, source),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un contrôle sans libellé propre, étiqueté au-dessus.
class ExpenseLabelled extends StatelessWidget {
  final String label;
  final Widget child;

  const ExpenseLabelled({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTextStyles.caption),
      const SizedBox(height: AppDimensions.expenseInlineGap),
      child,
    ],
  );
}

/// L'encart de pied : la source de fonds ne débite rien. Promettre un effet
/// de caisse absent serait la pire des dettes d'interface.
class ExpenseFundingNote extends StatelessWidget {
  const ExpenseFundingNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(
        AppDimensions.spacingS + AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.expenseFormFundingNote,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
