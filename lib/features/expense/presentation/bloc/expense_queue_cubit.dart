import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_message.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/load_expense_thread_use_case.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_queue_state.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_snapshot_source.dart';

/// Ce qu'un lot a produit — **compté en local**, geste par geste (F23).
///
/// Champs nommés : `(3, 1)` ne dit pas lequel des deux est l'échec.
typedef ExpenseBatchOutcome = ({int done, int failed});

/// Dépenses ▸ Validations — la file des demandes en attente.
///
/// Elle lit le **même** instantané local que les deux autres écrans, mais
/// ignore leur période : une demande déposée le mois dernier attend toujours.
class ExpenseQueueCubit extends Cubit<ExpenseQueueState> {
  final ExpenseSnapshotSource _source;
  final ApplyExpenseGestureUseCase _gesture;
  final LoadExpenseThreadUseCase _thread;
  final DateTime Function() _now;
  void Function()? _unwatch;

  ExpenseQueueCubit({
    required ExpenseSnapshotSource source,
    required ApplyExpenseGestureUseCase gesture,
    required LoadExpenseThreadUseCase thread,
    DateTime Function() now = DateTime.now,
  }) : _source = source,
       _gesture = gesture,
       _thread = thread,
       _now = now,
       super(ExpenseQueueState.initial(today: now()));

  Future<void> load() async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading, clearFailure: true));
    final result = await _source.read();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: ExpenseLoadStatus.failure, failure: failure),
      ),
      _emitReady,
    );
    _unwatch ??= _source.watch(() => unawaited(refresh()));
  }

  /// Relecture **silencieuse** — jamais de squelette, et un échec garde
  /// l'écran tel quel : une lecture de confort ne remonte pas d'erreur
  /// par-dessus des données déjà affichées.
  Future<void> refresh() async {
    if (isClosed) return;
    final result = await _source.read();
    if (isClosed) return;
    result.fold((_) {}, _emitReady);
  }

  void _emitReady(ExpenseRegisterSnapshot snapshot) => emit(
    state.copyWith(
      status: ExpenseLoadStatus.ready,
      snapshot: snapshot,
      today: _now(),
      clearFailure: true,
    ),
  );

  // ── Lecture ───────────────────────────────────────────────────────────

  void setSort(ExpenseQueueSort sort) {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
  }

  // ── Sélection ─────────────────────────────────────────────────────────

  void toggleSelection(String expenseId) {
    final next = {...state.selection};
    if (!next.remove(expenseId)) next.add(expenseId);
    emit(state.copyWith(selection: next));
  }

  /// Tout ou rien — sur la file **visible**, celle que l'écran montre.
  void toggleAll() => emit(
    state.copyWith(
      selection: state.allSelected
          ? const <String>{}
          : {for (final expense in state.view.pending) expense.id},
    ),
  );

  void clearSelection() {
    if (state.selection.isEmpty) return;
    emit(state.copyWith(selection: const <String>{}));
  }

  /// Les demandes cochées, **dans l'ordre de la file** : c'est celui-là que
  /// le lot rejoue, et c'est celui que le toast de synthèse résume.
  List<Expense> get selectedExpenses => [
    for (final expense in state.view.pending)
      if (state.selection.contains(expense.id)) expense,
  ];

  // ── Écriture ──────────────────────────────────────────────────────────

  Future<Either<Failure, Unit>> applyGesture(
    Expense expense,
    ExpenseGesture gesture, {
    String note = '',
    String? actorName,
  }) async {
    final result = await _gesture(
      expense,
      gesture,
      note: note,
      actorName: actorName,
    );
    await refresh();
    return result;
  }

  /// Le lot : **un geste d'écran, pas un appel réseau** (F23, le back a
  /// retiré sa route de lot).
  ///
  /// Chaque demande produit son propre geste, son propre message et — à
  /// DEP-14 — sa propre entrée d'outbox. Un refus en lot recopie le même
  /// motif dans chacun.
  ///
  /// Séquentiel, jamais en parallèle : les gestes d'une même dépense doivent
  /// partir dans l'ordre (F31), et deux écritures concurrentes sur la même
  /// base se disputeraient la transaction pour rien.
  ///
  /// Une seule relecture **à la fin** : relire après chaque ligne ferait
  /// clignoter la file autant de fois qu'elle compte de demandes.
  Future<ExpenseBatchOutcome> applyBatch(
    List<Expense> expenses,
    ExpenseGesture gesture, {
    String note = '',
    String? actorName,
  }) async {
    var done = 0;
    var failed = 0;
    for (final expense in expenses) {
      final result = await _gesture(
        expense,
        gesture,
        note: note,
        actorName: actorName,
      );
      result.fold((_) => failed++, (_) => done++);
      if (isClosed) break;
    }
    await refresh();
    if (!isClosed) clearSelection();
    return (done: done, failed: failed);
  }

  /// Le fil d'une demande, lu à l'ouverture de sa fiche.
  Future<Either<Failure, List<ExpenseMessage>>> thread(String expenseId) =>
      _thread(expenseId);

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}
