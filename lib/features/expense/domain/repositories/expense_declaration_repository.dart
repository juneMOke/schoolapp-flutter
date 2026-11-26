import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_declaration_draft.dart';

/// Déclarer une dépense déjà payée (v3) : la ligne, sa photo, son fil et son
/// entrée d'envoi, écrits ensemble sur le poste.
abstract class ExpenseDeclarationRepository {
  Future<Either<Failure, Expense>> declare(ExpenseDeclarationDraft draft);
}
