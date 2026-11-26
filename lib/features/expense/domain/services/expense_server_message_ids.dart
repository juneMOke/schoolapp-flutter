import 'package:uuid/uuid.dart';

/// Les identifiants des messages que le **serveur** écrit au fil d'une
/// dépense — fabriqués d'avance sur le poste, à l'identique (Q5).
///
/// RFC 4122 v5 standard, comme `NameBasedIds.of` du serveur : l'espace de
/// noms est **l'uuid de la dépense lui-même**, le nom est l'acte seul, en
/// UTF-8. Aucune composition (« expense:{id}:… »), aucun espace fixe.
abstract final class ExpenseServerMessageIds {
  static const Uuid _uuid = Uuid();

  /// Le message `VISA` d'un visa d'office (F41).
  static String visa(String expenseId) => _uuid.v5(expenseId, 'VISA');

  /// Le message `DEPOSIT` d'une demande d'autorisation.
  static String deposit(String expenseId) => _uuid.v5(expenseId, 'DEPOSIT');
}
