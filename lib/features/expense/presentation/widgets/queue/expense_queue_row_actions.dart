import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_gesture_policy.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_act_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_gesture_access.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_row_actions.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes à portée de main d'une ligne de file.
///
/// **Décider est nommé, le reste est une icône** : c'est le travail qu'on
/// vient faire ici, et deux boutons libellés valent mieux que deux
/// pictogrammes qu'il faut survoler. Les gestes du demandeur restent des
/// icônes — ils sont rares sur la file d'un décideur, et la fiche les redit
/// en toutes lettres.
///
/// Mêmes trois filtres qu'à la fiche (F29) : permission × état × propriété.
class ExpenseQueueRowActions extends StatelessWidget {
  final Expense expense;
  final String? accountId;

  /// Refuser ne part pas d'ici : la fiche s'ouvre avec son panneau de motif.
  final VoidCallback onRefuse;
  final ValueChanged<ExpenseGesture> onGesture;
  final VoidCallback onOpen;

  const ExpenseQueueRowActions({
    super.key,
    required this.expense,
    required this.accountId,
    required this.onRefuse,
    required this.onGesture,
    required this.onOpen,
  });

  /// Ce que le demandeur peut faire sans quitter la file. `comment` n'y est
  /// pas : commenter se fait dans le fil, donc dans la fiche.
  static const List<ExpenseGesture> _quiet = [
    ExpenseGesture.remind,
    ExpenseGesture.retract,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offered = ExpenseGesturePolicy.offeredOn(
      expense,
      accountId: accountId,
    );
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.spacingXS,
      runSpacing: AppDimensions.spacingXS,
      children: [
        for (final gesture in _quiet)
          if (offered.contains(gesture))
            PermissionGate.access(
              expenseGestureAccess(gesture),
              child: ExpenseRowAction(
                icon: expenseActVisuals(gesture.act).icon,
                tooltip: expenseGestureLabel(l10n, gesture),
                onPressed: () => onGesture(gesture),
              ),
            ),
        ExpenseRowAction(
          icon: Icons.forum_outlined,
          tooltip: l10n.expenseQueueOpenRequest,
          onPressed: onOpen,
        ),
        if (offered.contains(ExpenseGesture.refuse))
          PermissionGate.access(
            expenseGestureAccess(ExpenseGesture.refuse),
            child: EteeloButton.secondary(
              label: expenseGestureLabel(l10n, ExpenseGesture.refuse),
              icon: Icons.cancel_outlined,
              onPressed: onRefuse,
              fullWidth: false,
            ),
          ),
        if (offered.contains(ExpenseGesture.approve))
          PermissionGate.access(
            expenseGestureAccess(ExpenseGesture.approve),
            child: EteeloButton.primary(
              label: expenseGestureLabel(l10n, ExpenseGesture.approve),
              icon: Icons.verified_outlined,
              onPressed: () => onGesture(ExpenseGesture.approve),
              fullWidth: false,
            ),
          ),
      ],
    );
  }
}
