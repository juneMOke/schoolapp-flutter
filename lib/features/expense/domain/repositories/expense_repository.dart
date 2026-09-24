import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';

/// Le registre des dépenses du poste : lecture locale, écriture en file.
///
/// Toute écriture réussit **localement** d'abord (ADR-003) : un refus serveur
/// arrive plus tard, dans l'accusé, et la ligne porte alors son motif (A4).
/// Un `Left` ne signale donc qu'une panne du poste lui-même (base, session).
abstract class ExpenseRepository {
  Future<Either<Failure, ExpenseRegisterSnapshot>> loadRegister();

  /// Crée, modifie ou duplique ; rend la dépense telle qu'elle est rangée.
  Future<Either<Failure, Expense>> save(ExpenseDraft draft);

  /// Retire la dépense du registre (D4) — réversible par [restore].
  Future<Either<Failure, Unit>> withdraw(Expense expense);

  /// Le « Annuler » du toast.
  Future<Either<Failure, Unit>> restore(Expense expense);

  /// Le fil d'une demande, du plus ancien au plus récent (F30) — lecture
  /// locale, comme le reste du module.
  Future<Either<Failure, List<ExpenseMessage>>> thread(String expenseId);

  /// Applique un **geste du circuit** : la demande bouge et son fil s'allonge,
  /// dans une seule transaction.
  ///
  /// [note] est le corps du message — **obligatoire** pour un refus (le
  /// serveur répond `422 REASON_REQUIRED`) et pour un commentaire, facultatif
  /// partout ailleurs. [actorName] sert l'affichage ; c'est l'identifiant de
  /// la session, jamais ce nom, qui sert les comparaisons (F24).
  ///
  /// La demande passée sert à décider quoi offrir ; le dépôt **relit** la
  /// ligne avant d'écrire, et refuse le geste si l'état a changé entre-temps.
  Future<Either<Failure, Unit>> applyGesture(
    Expense expense,
    ExpenseGesture gesture, {
    String note = '',
    String? actorName,
  });
}
