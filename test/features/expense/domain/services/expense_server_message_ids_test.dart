import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_server_message_ids.dart';
import 'package:uuid/uuid.dart';

/// Vecteurs partagés avec le serveur (`ServerMessageIdsTest`), calculés par
/// son code Java et recoupés avec `uuid.uuid5` de Python le 2026-11-25. Si ce
/// test rougit, le visa d'office écrit d'avance doublera celui du serveur.
void main() {
  const expenseId = '7d0c5a8e-1b2f-4c3d-9e8f-0a1b2c3d4e5f';

  test('VISA et DEPOSIT donnent les ids du serveur', () {
    expect(
      ExpenseServerMessageIds.visa(expenseId),
      '97d3f5b8-da8d-5cf2-9fd1-a2a80dff56c2',
    );
    expect(
      ExpenseServerMessageIds.deposit(expenseId),
      '77d45430-dd26-5dbd-83c4-b8a0ba3a52fb',
    );
  });

  test('la bibliothèque suit la RFC (vecteur DNS)', () {
    expect(
      const Uuid().v5(Namespace.dns.value, 'www.example.com'),
      '2ed6657d-e927-568b-95e1-2665a8aea6a2',
    );
  });
}
