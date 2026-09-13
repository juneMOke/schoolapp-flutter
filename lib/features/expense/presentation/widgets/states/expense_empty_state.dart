import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux vides du registre (spec §13) : une période sans dépense n'a rien
/// à montrer, une recherche sans résultat a un filtre trop étroit. L'action
/// primaire est celle qui résout la cause.
///
/// Il remplace le registre SEUL : période, filtres et compteurs restent
/// au-dessus, ce sont eux qui expliquent le vide et permettent d'en sortir.
///
/// « Nouvelle dépense » passe par le garde des droits (réactif) : un compte
/// sans `expense.write` ne se voit jamais offrir un geste voué à l'échec.
class ExpenseEmptyState extends StatelessWidget {
  /// Des filtres vident une période qui, elle, a des dépenses.
  final bool filtered;

  /// « ce mois-ci » — la granularité, accordée.
  final String demonstrative;

  /// « septembre 2026 » — la période littérale, rejouée en clair.
  final String detail;

  final VoidCallback onCreate;
  final VoidCallback onResetFilters;

  /// `null` quand la fenêtre couvre déjà un mois ou plus : il n'y a rien à
  /// élargir.
  final VoidCallback? onShowWholeMonth;

  const ExpenseEmptyState({
    super.key,
    required this.filtered,
    required this.demonstrative,
    required this.detail,
    required this.onCreate,
    required this.onResetFilters,
    required this.onShowWholeMonth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (filtered) {
      return EteeloEmptyResult(
        label: l10n.expenseEmptySearchTitle,
        description: l10n.expenseEmptySearchMessage(detail),
        medallionIcon: Icons.search_rounded,
        fullWidthCard: true,
        primaryAction: EteeloButton.primary(
          label: l10n.expenseResetFilters,
          icon: Icons.restart_alt,
          onPressed: onResetFilters,
          fullWidth: false,
        ),
        secondaryAction: PermissionGate.access(
          kExpenseWriteAccess,
          child: EteeloButton.secondary(
            label: l10n.expenseNewAction,
            icon: Icons.add,
            onPressed: onCreate,
            fullWidth: false,
          ),
        ),
      );
    }
    final widen = onShowWholeMonth;
    return EteeloEmptyResult(
      label: l10n.expenseEmptyPeriodTitle(demonstrative),
      description: l10n.expenseEmptyPeriodMessage(detail),
      medallionIcon: Icons.date_range_outlined,
      fullWidthCard: true,
      primaryAction: PermissionGate.access(
        kExpenseWriteAccess,
        child: EteeloButton.primary(
          label: l10n.expenseNewAction,
          icon: Icons.add,
          onPressed: onCreate,
          fullWidth: false,
        ),
      ),
      secondaryAction: widen == null
          ? null
          : EteeloButton.secondary(
              label: l10n.expenseShowWholeMonth,
              icon: Icons.calendar_month_outlined,
              onPressed: widen,
              fullWidth: false,
            ),
    );
  }
}
