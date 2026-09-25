import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_day.dart';

/// Depuis combien de temps une demande attend, et à partir de quand cela se
/// voit (spec §05).
///
/// Deux seuils, pas un dégradé : **tiède à 3 jours, chaud à 5**. Un dégradé
/// continu ne se lirait pas d'un coup d'œil sur une file de trente lignes,
/// alors que deux paliers se comptent.
abstract final class ExpenseWait {
  /// La demande commence à traîner.
  static const int warmDays = 3;

  /// Elle est en retard, et la file le dit en rouge.
  static const int hotDays = 5;

  /// Jours **calendaires** écoulés depuis le dépôt.
  ///
  /// ⚠️ La date du dépôt n'a pas encore de colonne : c'est celle de la
  /// dépense qui en tient lieu, comme dans la maquette (`demandeLe || date`).
  /// Le serveur écrira l'instant réel avec son message `DEPOSIT`, que le pull
  /// rapportera (DEP-14) — l'attente sera alors comptée au jour près.
  ///
  /// Jamais négative : une dépense datée de demain n'attend pas « −1 jour ».
  static int daysWaiting(Expense expense, {required DateTime today}) {
    final days = ExpenseDay.spanInclusive(expense.expenseDate, today) - 1;
    return days < 0 ? 0 : days;
  }

  /// Au-delà du seuil chaud : c'est ce que la file compte comme retard.
  static bool isOverdue(Expense expense, {required DateTime today}) =>
      daysWaiting(expense, today: today) >= hotDays;

  /// Le demandeur a poussé au moins une fois.
  static bool wasReminded(Expense expense) => expense.reminderCount > 0;
}
