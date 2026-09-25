import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_gesture_policy.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_act_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_gesture_access.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/detail/expense_detail_outcome.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied de la fiche : les gestes que **cette** demande offre à **ce**
/// compte (F29).
///
/// Trois filtres, tous des ET : la permission (`PermissionGate.access`, qui
/// suit le droit sans que la fiche se reconstruise), l'état et la propriété
/// (`ExpenseGesturePolicy`). Aucun geste n'est offert pour échouer — un 403
/// comme un 422 sont terminaux dans notre classement, et le bouton fabriquerait
/// une ligne « à corriger » que son auteur ne pourrait pas corriger.
class ExpenseDetailActions extends StatelessWidget {
  final Expense expense;

  /// Le compte de la session : ce qui juge la propriété (F24).
  final String? accountId;

  final ValueChanged<ExpenseDetailChoice> onShortcut;
  final ValueChanged<ExpenseGesture> onGesture;

  /// Refuser ne part pas d'ici : le panneau de motif s'ouvre d'abord.
  final VoidCallback onRefuse;

  /// Supprimer, dupliquer et modifier rouvrent une modale de saisie, et cette
  /// saisie appartient au **registre**. La file ne les offre donc pas : un
  /// bouton qui renverrait vers un autre écran sans rien faire serait pire
  /// que son absence.
  final bool allowShortcuts;

  const ExpenseDetailActions({
    super.key,
    required this.expense,
    required this.accountId,
    required this.onShortcut,
    required this.onGesture,
    required this.onRefuse,
    this.allowShortcuts = true,
  });

  /// L'ordre du pied, de la reprise à la décision : ce que le demandeur peut
  /// faire d'abord, ce que le décideur tranche ensuite. Commenter n'y est
  /// pas — il vit dans le fil, avec son champ.
  static const List<ExpenseGesture> _order = [
    ExpenseGesture.retract,
    ExpenseGesture.remind,
    ExpenseGesture.resubmit,
    ExpenseGesture.reopen,
    ExpenseGesture.refuse,
    ExpenseGesture.approve,
    ExpenseGesture.pay,
  ];

  /// Les gestes qui closent une étape portent l'accent ; les autres
  /// l'attendent.
  static const Set<ExpenseGesture> _leading = {
    ExpenseGesture.resubmit,
    ExpenseGesture.approve,
    ExpenseGesture.pay,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offered = ExpenseGesturePolicy.offeredOn(
      expense,
      accountId: accountId,
    );
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: [
          // Supprimer : à gauche, en rouge, et seulement depuis la fiche — la
          // fiche est déjà un pas délibéré. Le mot nomme le RETRAIT DU
          // REGISTRE ; la reprise par son demandeur s'appelle « Retirer »
          // (F25).
          if (allowShortcuts)
            PermissionGate.access(
              kExpenseWithdrawAccess,
              child: TextButton.icon(
                onPressed: () => onShortcut(ExpenseDetailChoice.withdraw),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.expenseActionDelete),
              ),
            ),
          if (allowShortcuts)
            PermissionGate.access(
              kExpenseWriteAccess,
              child: Wrap(
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                children: [
                  EteeloButton.secondary(
                    label: l10n.expenseActionDuplicate,
                    icon: Icons.copy_outlined,
                    onPressed: () => onShortcut(ExpenseDetailChoice.duplicate),
                    fullWidth: false,
                  ),
                  // Modifier suit la même règle que les gestes du demandeur :
                  // tant que personne n'a décidé, et sur sa propre demande. Une
                  // dépense accordée dont on réécrirait le montant ne serait
                  // plus celle qui a été accordée.
                  if (expense.status == ExpenseStatus.pending &&
                      expense.isRequestedBy(accountId))
                    EteeloButton.secondary(
                      label: l10n.expenseActionEdit,
                      icon: Icons.edit_outlined,
                      onPressed: () => onShortcut(ExpenseDetailChoice.edit),
                      fullWidth: false,
                    ),
                ],
              ),
            ),
          for (final gesture in _order)
            if (offered.contains(gesture))
              PermissionGate.access(
                expenseGestureAccess(gesture),
                child: _GestureButton(
                  gesture: gesture,
                  leading: _leading.contains(gesture),
                  onPressed: () => gesture == ExpenseGesture.refuse
                      ? onRefuse()
                      : onGesture(gesture),
                ),
              ),
        ],
      ),
    );
  }
}

class _GestureButton extends StatelessWidget {
  final ExpenseGesture gesture;
  final bool leading;
  final VoidCallback onPressed;

  const _GestureButton({
    required this.gesture,
    required this.leading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = expenseGestureLabel(l10n, gesture);
    // L'icône du geste est celle de l'acte qu'il écrira au fil : le bouton et
    // la ligne qu'il produit se reconnaissent l'un l'autre.
    final icon = expenseActVisuals(gesture.act).icon;
    // ⚠️ Refuser reste `secondary` et non `danger` : le socle n'a pas de
    // variante rouge sortante, et deux boutons pleins côte à côte — Refuser
    // et Approuver — se disputeraient l'accent. Le rouge arrive au panneau de
    // motif, là où le refus se confirme.
    return leading
        ? EteeloButton.primary(
            label: label,
            icon: icon,
            onPressed: onPressed,
            fullWidth: false,
          )
        : EteeloButton.secondary(
            label: label,
            icon: icon,
            onPressed: onPressed,
            fullWidth: false,
          );
  }
}
