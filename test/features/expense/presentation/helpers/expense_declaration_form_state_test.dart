import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_declaration_form_state.dart';

/// E1 — le décaissement ne s'antidate pas.
void main() {
  test('une déclaration neuve est payée à l’instant de l’appui', () {
    final state = ExpenseDeclarationFormState();
    addTearDown(state.dispose);
    final now = DateTime.utc(2026, 11, 26, 9, 30);

    expect(state.disbursedAt(now), now);
  });

  test('une redéclaration garde l’instant d’origine, pas celui du jour', () {
    final origin = DateTime.utc(2026, 11, 25, 8, 12);
    final state = ExpenseDeclarationFormState.redeclaring(
      ExpenseRedeclaration(expenseId: 'e-1', disbursedAt: origin),
    );
    addTearDown(state.dispose);

    expect(state.disbursedAt(DateTime.utc(2026, 11, 26, 9, 30)), origin);
    expect(state.replacing, 'e-1');
  });
}
