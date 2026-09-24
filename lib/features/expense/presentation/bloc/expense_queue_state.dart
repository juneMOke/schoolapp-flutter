import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_queue_sort.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_queue_view.dart';

/// L'état de la file de validation.
///
/// Il partage [ExpenseLoadStatus] avec les deux autres écrans : c'est le même
/// automate, et le même instantané local en dessous.
class ExpenseQueueState extends Equatable {
  final ExpenseLoadStatus status;
  final ExpenseRegisterSnapshot snapshot;
  final ExpenseQueueSort sort;

  /// Les demandes cochées, par identifiant.
  ///
  /// **Purgée à chaque relecture** : une ligne décidée ailleurs, ou par le
  /// lot précédent, ne doit pas rester sélectionnée — un lot suivant la
  /// rejouerait pour rien.
  final Set<String> selection;

  final DateTime today;
  final Failure? failure;

  /// La projection de l'état, recalculée à chaque émission — les `buildWhen`
  /// comparent ainsi ce que l'écran montre, pas ce qui le produit.
  final ExpenseQueueView view;

  const ExpenseQueueState._({
    required this.status,
    required this.snapshot,
    required this.sort,
    required this.selection,
    required this.today,
    required this.failure,
    required this.view,
  });

  factory ExpenseQueueState.initial({required DateTime today}) =>
      ExpenseQueueState._compute(
        status: ExpenseLoadStatus.initial,
        snapshot: ExpenseRegisterSnapshot.empty,
        sort: ExpenseQueueSort.age,
        selection: const {},
        today: today,
        failure: null,
      );

  factory ExpenseQueueState._compute({
    required ExpenseLoadStatus status,
    required ExpenseRegisterSnapshot snapshot,
    required ExpenseQueueSort sort,
    required Set<String> selection,
    required DateTime today,
    required Failure? failure,
  }) {
    final view = ExpenseQueueView.compute(
      snapshot: snapshot,
      sort: sort,
      today: today,
    );
    final visible = {for (final expense in view.pending) expense.id};
    return ExpenseQueueState._(
      status: status,
      snapshot: snapshot,
      sort: sort,
      // La sélection ne survit jamais à la disparition de sa ligne.
      selection: selection.where(visible.contains).toSet(),
      today: today,
      failure: failure,
      view: view,
    );
  }

  ExpenseQueueState copyWith({
    ExpenseLoadStatus? status,
    ExpenseRegisterSnapshot? snapshot,
    ExpenseQueueSort? sort,
    Set<String>? selection,
    DateTime? today,
    Failure? failure,
    bool clearFailure = false,
  }) => ExpenseQueueState._compute(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    sort: sort ?? this.sort,
    selection: selection ?? this.selection,
    today: today ?? this.today,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  bool get isLoading =>
      status == ExpenseLoadStatus.initial ||
      status == ExpenseLoadStatus.loading;

  bool get hasSelection => selection.isNotEmpty;

  /// Toute la file est cochée — et la file n'est pas vide : « tout
  /// sélectionner » sur rien ne serait pas « tout ».
  bool get allSelected =>
      view.pending.isNotEmpty && selection.length == view.pending.length;

  @override
  List<Object?> get props => [
    status,
    snapshot,
    sort,
    selection,
    today,
    failure,
  ];
}
