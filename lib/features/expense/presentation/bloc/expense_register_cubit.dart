import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_period_memory.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_snapshot_source.dart';

/// Le registre « Frais de fonctionnement » : lecture locale, filtres en
/// mémoire, et les quatre gestes d'écriture.
///
/// Chaque geste réussit **localement** d'abord ; le cubit relit ensuite le
/// registre en silence. Un refus serveur arrivera plus tard, dans l'accusé,
/// et la relecture de fin de flush le fera apparaître sur la ligne (A4).
class ExpenseRegisterCubit extends Cubit<ExpenseRegisterState> {
  final ExpenseSnapshotSource _source;
  final ExpensePeriodMemory _memory;
  final SaveExpenseUseCase _save;
  final WithdrawExpenseUseCase _withdraw;
  final RestoreExpenseUseCase _restore;
  final DateTime Function() _now;
  void Function()? _unwatch;

  ExpenseRegisterCubit({
    required ExpenseSnapshotSource source,
    required ExpensePeriodMemory memory,
    required SaveExpenseUseCase save,
    required WithdrawExpenseUseCase withdraw,
    required RestoreExpenseUseCase restore,
    DateTime Function() now = DateTime.now,
  }) : _source = source,
       _memory = memory,
       _save = save,
       _withdraw = withdraw,
       _restore = restore,
       _now = now,
       super(
         ExpenseRegisterState.initial(
           period: memory.period,
           today: now(),
           typeFilter: memory.takeTypeFilter(),
         ),
       );

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

  /// Relecture **silencieuse** : elle ne passe jamais par le squelette, et un
  /// échec garde l'écran tel quel — une lecture de confort ne remonte jamais
  /// d'erreur par-dessus des données déjà affichées.
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

  // ── Période ───────────────────────────────────────────────────────────

  void setPeriod(ExpensePeriod period) {
    _memory.period = period;
    emit(state.copyWith(period: period, today: _now(), resetLimit: true));
  }

  void setGranularity(ExpenseGranularity value) =>
      setPeriod(state.period.withGranularity(value));

  void previousPeriod() => setPeriod(state.period.previous());

  void nextPeriod() => setPeriod(state.period.next());

  void currentPeriod() => setPeriod(state.period.current());

  /// « Voir le mois entier » — l'issue du vide « période sans dépense » :
  /// le mois de la journée ou de la semaine consultée.
  void showWholeMonth() =>
      setPeriod(ExpensePeriod.monthOf(state.view.range.from, today: _now()));

  // ── Filtres ───────────────────────────────────────────────────────────

  void toggleType(String typeId) => emit(
    state.copyWith(query: state.query.toggleType(typeId), resetLimit: true),
  );

  void clearTypes() =>
      emit(state.copyWith(query: state.query.withoutTypes(), resetLimit: true));

  void setStatusFilter(ExpenseStatus? status) => emit(
    state.copyWith(query: state.query.withStatus(status), resetLimit: true),
  );

  void setText(String text) {
    if (text == state.query.text) return;
    emit(state.copyWith(query: state.query.withText(text), resetLimit: true));
  }

  /// Types, statut et texte d'un coup — l'issue du vide « recherche ».
  void resetFilters() =>
      emit(state.copyWith(query: ExpenseQuery.none, resetLimit: true));

  void showMore() =>
      emit(state.copyWith(limit: state.limit + ExpenseRegisterState.pageSize));

  // ── Gestes ────────────────────────────────────────────────────────────

  Future<Either<Failure, Expense>> save(ExpenseDraft draft) =>
      _thenRefresh(_save(draft));

  // La bascule payée / non payée de la V1 a disparu avec le circuit : le
  // statut ne change plus que par un geste de décision, qui arrive au lot
  // suivant avec sa permission et son message de fil.

  Future<Either<Failure, Unit>> withdraw(Expense expense) =>
      _thenRefresh(_withdraw(expense));

  Future<Either<Failure, Unit>> restore(Expense expense) =>
      _thenRefresh(_restore(expense));

  Future<T> _thenRefresh<T>(Future<T> write) async {
    final result = await write;
    await refresh();
    return result;
  }

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}
