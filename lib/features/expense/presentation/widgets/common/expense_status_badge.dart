import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cinq états du circuit — une icône et un mot en plus de la teinte : la
/// couleur ne porte jamais seule une information.
///
/// Les teintes viennent des jetons du socle, jamais des hexadécimaux de la
/// spec : l'attente et le refus empruntent la famille des frais (même ambre,
/// même rouge), l'approbation le bleu de marque, le retrait l'encre muette.
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
    final visuals = _visualsOf(status);
    return _Pill(
      icon: visuals.icon,
      label: expenseStatusLabel(l10n, status),
      color: visuals.color,
      soft: visuals.soft,
      border: visuals.border,
      small: small,
    );
  }
}

/// Champs **nommés** : un enregistrement positionnel de quatre couleurs se
/// lirait de travers au premier changement d'ordre, sans que rien ne le dise.
typedef _StatusVisuals = ({
  Color color,
  Color soft,
  Color border,
  IconData icon,
});

_StatusVisuals _visualsOf(ExpenseStatus status) => switch (status) {
  ExpenseStatus.pending => (
    color: AppColors.feeStatusPartial,
    soft: AppColors.feeStatusPartialSoft,
    border: AppColors.feeStatusPartialBorder,
    icon: Icons.schedule,
  ),
  ExpenseStatus.approved => (
    color: AppColors.bleuArdoise,
    soft: AppColors.bleuArdoiseSoft,
    border: AppColors.border,
    icon: Icons.verified_outlined,
  ),
  ExpenseStatus.paid => (
    color: AppColors.feeStatusPaid,
    soft: AppColors.feeStatusPaidSoft,
    border: AppColors.feeStatusPaidBorder,
    icon: Icons.check_circle_outline,
  ),
  ExpenseStatus.refused => (
    color: AppColors.feeStatusDue,
    soft: AppColors.feeStatusDueSoft,
    border: AppColors.feeStatusDueBorder,
    icon: Icons.cancel_outlined,
  ),
  ExpenseStatus.retracted => (
    color: AppColors.textMuted,
    soft: AppColors.surfaceAlt,
    border: AppColors.border,
    icon: Icons.undo,
  ),
};

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
      ExpenseStatus.pending => l10n.expenseStatusPending,
      ExpenseStatus.approved => l10n.expenseStatusApproved,
      ExpenseStatus.paid => l10n.expenseStatusPaid,
      ExpenseStatus.refused => l10n.expenseStatusRefused,
      ExpenseStatus.retracted => l10n.expenseStatusRetracted,
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
