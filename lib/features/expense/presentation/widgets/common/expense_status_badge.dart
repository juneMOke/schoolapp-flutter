import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_status_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cinq états du circuit — une icône et un mot en plus de la teinte : la
/// couleur ne porte jamais seule une information.
///
/// Les teintes viennent de `expenseStatusVisuals`, partagé avec la chaîne de
/// validation.
class ExpenseStatusBadge extends StatelessWidget {
  final ExpenseStatus status;
  final bool small;

  /// Une déclaration annulée (F43) : `RETRACTED` se dit alors « Annulée »,
  /// jamais « Retirée » — personne ne l'a reprise, la direction l'a défaite.
  final bool cancelledDeclaration;

  const ExpenseStatusBadge({
    super.key,
    required this.status,
    this.small = false,
    this.cancelledDeclaration = false,
  });

  /// La pastille de [expense], déclaration comprise.
  factory ExpenseStatusBadge.of(Expense expense, {bool small = false}) =>
      ExpenseStatusBadge(
        status: expense.status,
        small: small,
        cancelledDeclaration: expense.isCancelledDeclaration,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visuals = expenseStatusVisuals(status);
    return _Pill(
      icon: cancelledDeclaration ? Icons.block : visuals.icon,
      label: cancelledDeclaration
          ? l10n.expenseStatusCancelled
          : expenseStatusLabel(l10n, status),
      color: visuals.color,
      soft: visuals.soft,
      border: visuals.border,
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
        // Une déclaration refusée ne se corrige pas, elle se régularise :
        // l'argent est sorti (F45).
        label: expense.isDeclarationToRegularize
            ? l10n.expenseSyncToRegularize
            : l10n.expenseSyncRejected,
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

/// Le **visa** d'une déclaration (v3) : à viser, visée, signalée. Le second
/// axe, montré à côté de la pastille d'état et jamais à sa place. Rien hors
/// déclaration, ni sur une déclaration annulée.
class ExpenseVisaBadge extends StatelessWidget {
  final Expense expense;
  final bool small;

  const ExpenseVisaBadge({super.key, required this.expense, this.small = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visa = expense.visaStatus;
    if (visa == null || expense.isCancelledDeclaration) {
      return const SizedBox.shrink();
    }
    return switch (visa) {
      ExpenseVisaStatus.pending => _Pill(
        icon: Icons.pending_actions_outlined,
        label: l10n.expenseVisaPending,
        color: AppColors.feeStatusPartialInk,
        soft: AppColors.feeStatusPartialSoft,
        border: AppColors.feeStatusPartialBorder,
        small: small,
      ),
      ExpenseVisaStatus.visaed => _Pill(
        icon: Icons.verified_outlined,
        label: l10n.expenseVisaVisaed,
        color: AppColors.bleuArdoise,
        soft: AppColors.bleuArdoiseSoft,
        border: AppColors.border,
        small: small,
      ),
      ExpenseVisaStatus.flagged => _Pill(
        icon: Icons.flag_outlined,
        label: l10n.expenseVisaFlagged,
        color: AppColors.feeStatusDue,
        soft: AppColors.feeStatusDueSoft,
        border: AppColors.feeStatusDueBorder,
        small: small,
      ),
    };
  }
}

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
