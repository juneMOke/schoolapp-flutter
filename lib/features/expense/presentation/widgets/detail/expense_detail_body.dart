import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_type_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_status_badge.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps de la fiche (spec §8) : le montant en tête, à l'échelle du titre
/// — c'est le fait que l'on vient vérifier — puis un tableau de références.
class ExpenseDetailBody extends StatelessWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;

  const ExpenseDetailBody({
    super.key,
    required this.expense,
    required this.type,
    required this.reader,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final paidOn = expense.paidOn;
    final rows = <(String, String)>[
      (l10n.expenseDetailType, type?.label ?? l10n.expenseTypeUnknown),
      (l10n.expenseDetailSupplier, expense.supplier ?? l10n.expenseNoSupplier),
      (
        l10n.expenseDetailFunding,
        expenseFundingLabel(l10n, expense.fundingSource),
      ),
      (
        l10n.expenseDetailRecordedBy,
        expense.recordedByName ?? l10n.expenseNoValue,
      ),
      (l10n.expenseDetailDate, dates.formatFullDate(expense.expenseDate)),
      // A2 — « Payée le … » : la date qui comptera le jour où la source de
      // fonds débitera la caisse.
      if (expense.isPaid)
        (
          l10n.expenseDetailPaidOn,
          paidOn == null ? l10n.expenseNoValue : dates.formatFullDate(paidOn),
        ),
      (
        l10n.expenseDetailNumber,
        expense.number ?? l10n.expenseDetailNumberPending,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Banner(expense: expense, type: type, reader: reader),
        if (expense.isRejected) ...[
          const SizedBox(
            height: AppDimensions.spacingS + AppDimensions.spacingXS,
          ),
          _Rejection(code: expense.syncErrorCode),
        ],
        const SizedBox(height: AppDimensions.spacingM),
        expense.description == null
            ? Text(
                l10n.expenseDetailNoDescription,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              )
            : Text(
                expense.description!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
        const SizedBox(
          height: AppDimensions.spacingS + AppDimensions.spacingXS,
        ),
        for (var i = 0; i < rows.length; i++)
          _ReferenceRow(
            label: rows[i].$1,
            value: rows[i].$2,
            last: i == rows.length - 1,
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Expense expense;
  final ExpenseType? type;
  final ExpenseUsdReader reader;

  const _Banner({
    required this.expense,
    required this.type,
    required this.reader,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ExpenseTypeColors.of(type);
    final usd = ExpenseMoneyText.showsUsdEquivalent(expense.currency)
        ? reader.usdCentsOf(Money(expense.amountInCents, expense.currency))
        : null;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: colors.soft,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.expenseInsetRadius),
      ),
      child: Row(
        children: [
          Container(
            width: AppDimensions.expenseDetailMedallionSize,
            height: AppDimensions.expenseDetailMedallionSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(
                AppDimensions.expenseInsetRadius,
              ),
            ),
            child: Icon(
              type == null
                  ? ExpenseTypeVisuals.fallbackIcon
                  : ExpenseTypeVisuals.icon(type!.icon),
              size: AppDimensions.expenseDetailMedallionIconSize,
              color: colors.color,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ExpenseMoneyText.of(expense),
                  style: AppTextStyles.totalAmountLora,
                ),
                if (usd != null)
                  Text(
                    l10n.expenseUsdEquivalentOfDay(ExpenseMoneyText.usd(usd)),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          ExpenseStatusBadge(status: expense.status),
        ],
      ),
    );
  }
}

/// A4 — le refus serveur, porté par la ligne elle-même.
class _Rejection extends StatelessWidget {
  final String? code;

  const _Rejection({required this.code});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(
        AppDimensions.spacingS + AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.financeDetailDangerSoft,
        border: Border.all(color: AppColors.feeStatusDueBorder),
        borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.error,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.expenseDetailRejected(expenseRejectionLabel(l10n, code)),
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _ReferenceRow({
    required this.label,
    required this.value,
    required this.last,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: AppDimensions.expenseNotePaddingV,
    ),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppDimensions.expenseDetailLabelWidth,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS + AppDimensions.spacingXS),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    ),
  );
}
