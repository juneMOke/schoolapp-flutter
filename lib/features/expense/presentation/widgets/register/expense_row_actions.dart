import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le geste à portée de main d'une ligne : dupliquer. Masqué sans
/// `expense.write` — un geste d'outbox offert sans le droit mourrait plus
/// tard, en silence (403 terminal).
///
/// La bascule payée / non payée de la V1 a disparu avec le circuit : décider
/// n'est plus un clic de liste, et les gestes de décision arrivent au lot
/// suivant, avec leur permission et leur message de fil.
class ExpenseRowActions extends StatelessWidget {
  final VoidCallback onDuplicate;

  const ExpenseRowActions({super.key, required this.onDuplicate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate.access(
      kExpenseWriteAccess,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
