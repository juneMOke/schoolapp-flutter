import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux gestes à portée de main d'une ligne (spec §6) : basculer le
/// statut et dupliquer. Masqués sans `expense.write` — un geste d'outbox
/// offert sans le droit mourrait plus tard, en silence (403 terminal).
class ExpenseRowActions extends StatelessWidget {
  final Expense expense;
  final VoidCallback onToggle;
  final VoidCallback onDuplicate;

  const ExpenseRowActions({
    super.key,
    required this.expense,
    required this.onToggle,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate.access(
      kExpenseWriteAccess,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExpenseRowAction(
            // L'icône montre l'ACTION, pas l'état — l'état est dans le badge.
            icon: expense.isPaid ? Icons.undo : Icons.check,
            tooltip: expense.isPaid
                ? l10n.expenseActionMarkUnpaid
                : l10n.expenseActionMarkPaid,
            onPressed: onToggle,
          ),
          const SizedBox(width: AppDimensions.expenseInlineGap),
          ExpenseRowAction(
            icon: Icons.copy_outlined,
            tooltip: l10n.expenseActionDuplicate,
            onPressed: onDuplicate,
          ),
        ],
      ),
    );
  }
}

/// Bouton 34 dp d'une ligne ; la zone de clic reste la cellule.
class ExpenseRowAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const ExpenseRowAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: AppDimensions.expenseRowActionIconSize,
    style: IconButton.styleFrom(
      fixedSize: const Size.square(AppDimensions.expenseRowActionSize),
      minimumSize: const Size.square(AppDimensions.expenseRowActionSize),
      backgroundColor: AppColors.surfaceRaised,
      foregroundColor: AppColors.bleuArdoise,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppDimensions.expenseRowActionRadius,
        ),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    icon: Icon(icon),
  );
}
