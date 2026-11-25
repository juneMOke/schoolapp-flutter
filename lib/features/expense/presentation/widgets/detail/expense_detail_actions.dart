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

  /// Signaler non plus : le motif est obligatoire (v3).
  final VoidCallback? onFlag;

  /// La photo du bon est sur ce poste : « Viser » s'ouvre (F40). On ne vise
  /// pas un bon qu'on n'a pas vu.
  final bool voucherSeen;

  /// « Annuler » reste offert sur cette déclaration (F44).
  final bool cancelAllowed;

  /// La session peut redéclarer une déclaration refusée (F45).
  final bool canRedeclare;

  /// Supprimer, dupliquer et modifier rouvrent une modale de saisie, et cette
  /// saisie appartient au **registre**. La file ne les offre donc pas : un
  /// bouton qui renverrait vers un autre écran sans rien faire serait pire
  /// que son absence.
  final bool allowShortcuts;

  /// Une avance au personnel, bloc R.H. caviardé compris : elle ne se
  /// duplique pas (B5).
  final bool isStaffAdvance;

  const ExpenseDetailActions({
    super.key,
    required this.expense,
    required this.accountId,
    this.isStaffAdvance = false,
    required this.onShortcut,
    required this.onGesture,
    required this.onRefuse,
    this.allowShortcuts = true,
    this.onFlag,
    this.voucherSeen = false,
    this.cancelAllowed = true,
    this.canRedeclare = false,
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
    ExpenseGesture.flag,
    ExpenseGesture.visa,
  ];

  /// Les gestes qui closent une étape portent l'accent ; les autres
  /// l'attendent.
  static const Set<ExpenseGesture> _leading = {
    ExpenseGesture.resubmit,
    ExpenseGesture.approve,
    ExpenseGesture.pay,
    ExpenseGesture.visa,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offered = ExpenseGesturePolicy.offeredOn(
      expense,
      accountId: accountId,
    );
    final declaration = expense.isDeclaration;
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
          // Une déclaration ne se supprime pas : l'argent est sorti. Elle
          // s'annule (sous la garde de la clôture) ou se redéclare.
          if (allowShortcuts && !declaration)
            PermissionGate.access(
              kExpenseWithdrawAccess,
              child: TextButton.icon(
                onPressed: () => onShortcut(ExpenseDetailChoice.withdraw),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.expenseActionDelete),
              ),
            ),
          if (allowShortcuts &&
              canRedeclare &&
              expense.isDeclarationToRegularize)
            PermissionGate.access(
              kExpenseDeclareAccess,
              child: EteeloButton.primary(
                label: l10n.expenseActionRedeclare,
                icon: Icons.receipt_long_outlined,
                onPressed: () => onShortcut(ExpenseDetailChoice.redeclare),
                fullWidth: false,
              ),
            ),
          // Une déclaration est payée : ni dupliquée ni modifiée ici — on la
          // redéclare si elle a été refusée.
          if (allowShortcuts && !declaration)
            PermissionGate.access(
              kExpenseWriteAccess,
              child: Wrap(
                spacing: AppDimensions.spacingS,
                runSpacing: AppDimensions.spacingS,
                children: [
                  // Une avance au personnel ne se duplique pas : elle se
                  // dépose depuis la Paie, avec son bloc R.H. (B5).
                  if (!isStaffAdvance)
                    EteeloButton.secondary(
                      label: l10n.expenseActionDuplicate,
                      icon: Icons.copy_outlined,
                      onPressed: () =>
                          onShortcut(ExpenseDetailChoice.duplicate),
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
            if (offered.contains(gesture) &&
                !(declaration &&
                    gesture == ExpenseGesture.reopen &&
                    !cancelAllowed))
              PermissionGate.access(
                expenseGestureAccess(gesture),
                child: _GestureButton(
                  gesture: gesture,
                  declaration: declaration,
                  leading: _leading.contains(gesture),
                  // « Viser » attend la photo : désactivé, avec son pourquoi.
                  tooltip: gesture == ExpenseGesture.visa && !voucherSeen
                      ? l10n.expenseVisaNeedsVoucher
                      : null,
                  onPressed: switch (gesture) {
                    ExpenseGesture.refuse => onRefuse,
                    ExpenseGesture.flag => onFlag,
                    ExpenseGesture.visa when !voucherSeen => null,
                    _ => () => onGesture(gesture),
                  },
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
  final bool declaration;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _GestureButton({
    required this.gesture,
    required this.leading,
    required this.onPressed,
    this.declaration = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = expenseGestureLabel(l10n, gesture, declaration: declaration);
    // L'icône du geste est celle de l'acte qu'il écrira au fil : le bouton et
    // la ligne qu'il produit se reconnaissent l'un l'autre.
    final icon = expenseActVisuals(gesture.act).icon;
    // ⚠️ Refuser reste `secondary` et non `danger` : le socle n'a pas de
    // variante rouge sortante, et deux boutons pleins côte à côte — Refuser
    // et Approuver — se disputeraient l'accent. Le rouge arrive au panneau de
    // motif, là où le refus se confirme.
    final button = leading
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
    final tooltip = this.tooltip;
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
