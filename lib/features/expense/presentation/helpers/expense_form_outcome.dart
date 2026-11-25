import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';

/// Ce que rend le formulaire d'une dépense : une demande (à autoriser, ou
/// modifiée), ou une déclaration (v3). Deux chemins d'écriture distincts.
sealed class ExpenseFormOutcome {
  const ExpenseFormOutcome();
}

class ExpenseFormRequest extends ExpenseFormOutcome {
  final ExpenseDraft draft;

  const ExpenseFormRequest(this.draft);
}

class ExpenseFormDeclaration extends ExpenseFormOutcome {
  final ExpenseDeclarationDraft draft;

  const ExpenseFormDeclaration(this.draft);
}
