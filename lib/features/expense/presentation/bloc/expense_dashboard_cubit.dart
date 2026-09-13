import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_period_memory.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_snapshot_source.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_dashboard_view.dart';

class ExpenseDashboardState extends Equatable {
  final ExpenseLoadStatus status;
  final ExpenseRegisterSnapshot snapshot;
  final ExpensePeriod period;
  final DateTime today;
  final Failure? failure;
  final ExpenseDashboardView view;

  const ExpenseDashboardState._({
    required this.status,
    required this.snapshot,
    required this.period,
    required this.today,
    required this.failure,
    required this.view,
  });

  factory ExpenseDashboardState.compute({
    required ExpenseLoadStatus status,
    required ExpenseRegisterSnapshot snapshot,
    required ExpensePeriod period,
    required DateTime today,
    Failure? failure,
  }) => ExpenseDashboardState._(
    status: status,
    snapshot: snapshot,
    period: period,
    today: today,
    failure: failure,
    view: ExpenseDashboardView.compute(
      snapshot: snapshot,
      period: period,
      today: today,
    ),
  );

  ExpenseDashboardState copyWith({
    ExpenseLoadStatus? status,
    ExpenseRegisterSnapshot? snapshot,
    ExpensePeriod? period,
    DateTime? today,
    Failure? failure,
    bool clearFailure = false,
  }) => ExpenseDashboardState.compute(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    period: period ?? this.period,
    today: today ?? this.today,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  bool get isLoading =>
      status == ExpenseLoadStatus.initial ||
      status == ExpenseLoadStatus.loading;

  @override
  List<Object?> get props => [status, snapshot, period, today, failure];
}

/// Le tableau de bord : les mêmes dépenses que le registre, agrégées sur la
/// même période. Lecture seule — c'est dans le registre, et nulle part
/// ailleurs, qu'une dépense s'écrit.
class ExpenseDashboardCubit extends Cubit<ExpenseDashboardState> {
  final ExpenseSnapshotSource _source;
  final ExpensePeriodMemory _memory;
  final DateTime Function() _now;
  void Function()? _unwatch;

  ExpenseDashboardCubit({
    required ExpenseSnapshotSource source,
    required ExpensePeriodMemory memory,
    DateTime Function() now = DateTime.now,
  }) : _source = source,
       _memory = memory,
       _now = now,
       super(
         ExpenseDashboardState.compute(
           status: ExpenseLoadStatus.initial,
           snapshot: ExpenseRegisterSnapshot.empty,
           period: memory.period,
           today: now(),
         ),
       );

  Future<void> load() async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading, clearFailure: true));
    await _read(silent: false);
    // Fermé pendant la lecture : s'abonner maintenant laisserait un écouteur
    // que plus aucun `close` ne retirera.
    if (isClosed) return;
    _unwatch ??= _source.watch(() => unawaited(_read(silent: true)));
  }

  Future<void> _read({required bool silent}) async {
    if (isClosed) return;
    final result = await _source.read();
    if (isClosed) return;
    result.fold(
      (failure) {
        // Une relecture de confort ne remonte jamais d'erreur par-dessus des
        // chiffres déjà affichés.
        if (silent) return;
        emit(
          state.copyWith(status: ExpenseLoadStatus.failure, failure: failure),
        );
      },
      (snapshot) => emit(
        state.copyWith(
          status: ExpenseLoadStatus.ready,
          snapshot: snapshot,
          today: _now(),
          clearFailure: true,
        ),
      ),
    );
  }

  void setPeriod(ExpensePeriod period) {
    _memory.period = period;
    emit(state.copyWith(period: period, today: _now()));
  }

  void setGranularity(ExpenseGranularity value) =>
      setPeriod(state.period.withGranularity(value));

  void previousPeriod() => setPeriod(state.period.previous());

  void nextPeriod() => setPeriod(state.period.next());

  void currentPeriod() => setPeriod(state.period.current());

  /// « Voir le mois entier » — l'issue du vide : le mois de la journée ou de
  /// la semaine consultée.
  void showWholeMonth() =>
      setPeriod(ExpensePeriod.monthOf(state.view.range.from, today: _now()));

  /// Ouvre le registre filtré sur ce poste, au prochain affichage.
  void requestRegisterType(String typeId) => _memory.requestTypeFilter(typeId);

  @override
  Future<void> close() {
    _unwatch?.call();
    return super.close();
  }
}
