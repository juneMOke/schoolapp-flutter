import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_advance_payment.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Les règles d'une dépense d'avance au personnel que le dépôt tient avant
/// d'écrire un geste (B6, T13) — refusées ici, elles ne partent jamais pour
/// mourir en 422 après que l'argent est sorti.
abstract final class ExpenseAdvanceRules {
  /// Payer une avance sans le mois de première retenue, ou sans sa preuve.
  static const proofRequired = ValidationFailure(
    'Avance au personnel : mois de première retenue et preuve requis.',
  );

  /// La paie du mois de première retenue n'est plus en brouillon.
  static const monthClosed = ConflictFailure(
    'La paie choisie pour la première retenue est fermée : choisissez-en une autre.',
  );

  /// Une retenue est figée : l'avance ne se rouvre plus.
  static const deducted = ConflictFailure(
    'Une retenue de cette avance est déjà figée : réouverture impossible.',
  );

  /// La paie de la première retenue, ou une suivante, est fermée : l'avance
  /// ne se rouvre plus.
  static const monthLocked = ConflictFailure(
    'La paie de la première retenue est déjà soumise ou validée : réouverture impossible.',
  );

  /// Espèces : la reconnaissance de dette signée ; sinon une référence.
  static bool proves(
    ExpenseAdvancePayment advance,
    ExpenseFundingSource source,
  ) => source == ExpenseFundingSource.cash
      ? advance.debtAcknowledged
      : (advance.reference?.trim().length ?? 0) >=
            ExpenseAdvancePayment.minReferenceLength;
}
