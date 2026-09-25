import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';

/// Le **troisième** filtre de F29 : la permission, croisée par-dessus l'état
/// et la propriété que `ExpenseGesturePolicy` a déjà tranchés.
///
/// Il vit ici, et non dans le domaine, parce que le domaine ne connaît pas la
/// session — et il vit dans **une** table, parce qu'un contrôle d'accès
/// recopié écran par écran finit toujours par diverger.
ModuleAccess expenseGestureAccess(ExpenseGesture gesture) => switch (gesture) {
  // Décider n'est pas saisir : c'est tout l'objet du circuit.
  ExpenseGesture.approve || ExpenseGesture.refuse => kExpenseDecideAccess,
  ExpenseGesture.pay => kExpensePayAccess,
  ExpenseGesture.reopen => kExpenseReopenAccess,
  // Les gestes du demandeur, et le commentaire, restent sous le droit
  // d'écriture du registre : ce sont des écritures sur sa propre demande —
  // sauf commenter, que le back a délibérément laissé sans contrôle de
  // propriété (Q1), pour que le validateur puisse répondre.
  ExpenseGesture.retract ||
  ExpenseGesture.resubmit ||
  ExpenseGesture.remind ||
  ExpenseGesture.comment => kExpenseWriteAccess,
};
