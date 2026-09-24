import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'encart de situation, sous la chaîne : ce que la demande attend, dit en
/// une phrase.
///
/// Deux situations seulement — c'est délibéré. Une demande accordée ou payée
/// n'a rien à ajouter : la chaîne le dit déjà, et répéter un état calme en
/// couleur ferait crier tous les écrans à la fois.
class ExpenseSituationNote extends StatelessWidget {
  final Expense expense;

  const ExpenseSituationNote({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = expense.decisionReason;
    return switch (expense.status) {
      // Le masquage est **réactif** : la phrase suit le droit, sans que la
      // fiche ait à se reconstruire. Le repli n'est pas vide — celui qui ne
      // décide pas doit lire que quelqu'un d'autre le fera, pas rien.
      ExpenseStatus.pending => PermissionGate.access(
        kExpenseDecideAccess,
        fallback: _Note(
          icon: Icons.schedule,
          ink: AppColors.feeStatusPartialInk,
          soft: AppColors.feeStatusPartialSoft,
          border: AppColors.feeStatusPartialBorder,
          body: l10n.expenseSituationAwaitingDecision,
        ),
        child: _Note(
          icon: Icons.schedule,
          ink: AppColors.feeStatusPartialInk,
          soft: AppColors.feeStatusPartialSoft,
          border: AppColors.feeStatusPartialBorder,
          body: l10n.expenseSituationDecide,
        ),
      ),
      // Un refus sans motif n'existe pas côté serveur ; s'il arrivait, mieux
      // vaut taire l'encart que titrer « Motif du refus » au-dessus du vide.
      ExpenseStatus.refused when reason != null && reason.isNotEmpty => _Note(
        icon: Icons.cancel_outlined,
        ink: AppColors.feeStatusDue,
        soft: AppColors.feeStatusDueSoft,
        border: AppColors.feeStatusDueBorder,
        title: l10n.expenseRefusalReasonBy(
          expense.decidedByName ?? l10n.expenseNoValue,
        ),
        body: reason,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final Color ink;
  final Color soft;
  final Color border;
  final String? title;
  final String body;

  const _Note({
    required this.icon,
    required this.ink,
    required this.soft,
    required this.border,
    required this.body,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS + AppDimensions.spacingXS,
        vertical: AppDimensions.expenseNotePaddingV,
      ),
      decoration: BoxDecoration(
        color: soft,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: ink),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: AppTextStyles.caption.copyWith(color: ink),
                  ),
                Text(
                  body,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
