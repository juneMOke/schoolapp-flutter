import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Payée / Non payée — une icône et un mot en plus de la teinte : la couleur
/// ne porte jamais seule une information.
class ExpenseStatusBadge extends StatelessWidget {
  final ExpenseStatus status;
  final bool small;

  const ExpenseStatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paid = status == ExpenseStatus.paid;
    return _Pill(
      icon: paid ? Icons.check_circle_outline : Icons.schedule,
      label: expenseStatusLabel(l10n, status),
      color: paid ? AppColors.feeStatusPaid : AppColors.feeStatusPartial,
      soft: paid ? AppColors.feeStatusPaidSoft : AppColors.feeStatusPartialSoft,
      border: paid
          ? AppColors.feeStatusPaidBorder
          : AppColors.feeStatusPartialBorder,
      small: small,
    );
  }
}

/// Où en est la remontée : « N° en attente » tant que le serveur n'a pas
/// numéroté la dépense (A3), « À corriger » quand il l'a refusée (A4). Rien
/// quand tout est accusé : le numéro se lit alors dans la ligne.
class ExpenseSyncBadge extends StatelessWidget {
  final Expense expense;
  final bool small;

  const ExpenseSyncBadge({super.key, required this.expense, this.small = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (expense.isRejected) {
      return _Pill(
        icon: Icons.error_outline,
        label: l10n.expenseSyncRejected,
        color: AppColors.error,
        soft: AppColors.financeDetailDangerSoft,
        border: AppColors.feeStatusDueBorder,
        small: small,
      );
    }
    if (expense.number == null) {
      return _Pill(
        icon: Icons.cloud_upload_outlined,
        label: l10n.expenseNumberPending,
        color: AppColors.textSecondary,
        soft: AppColors.surfaceAlt,
        border: AppColors.border,
        small: small,
      );
    }
    return const SizedBox.shrink();
  }
}

String expenseStatusLabel(AppLocalizations l10n, ExpenseStatus status) =>
    switch (status) {
      ExpenseStatus.paid => l10n.expenseStatusPaid,
      ExpenseStatus.unpaid => l10n.expenseStatusUnpaid,
    };

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color soft;
  final Color border;
  final bool small;

  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.soft,
    required this.border,
    required this.small,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: small ? AppDimensions.spacingS : AppDimensions.chipPaddingH,
      vertical: small
          ? AppDimensions.spacingXS / 2
          : AppDimensions.chipPaddingV,
    ),
    decoration: BoxDecoration(
      color: soft,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(AppDimensions.expenseChipRadius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: small
              ? AppDimensions.expenseStatusIconSizeSmall
              : AppDimensions.expenseStatusIconSize,
          color: color,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.badge.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
