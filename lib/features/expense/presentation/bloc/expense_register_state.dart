import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_register_query.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_register_view.dart';

/// Automate de chargement des deux écrans (spec §01) : `loading` n'est joué
/// qu'à l'ouverture — changer de période ou de filtre recalcule sur place.
enum ExpenseLoadStatus { initial, loading, ready, failure }

class ExpenseRegisterState extends Equatable {
  /// Palier du registre : 40 lignes, puis 40 de plus par clic.
  static const int pageSize = 40;

  final ExpenseLoadStatus status;
  final ExpenseRegisterSnapshot snapshot;
  final ExpensePeriod period;
  final ExpenseQuery query;
  final int limit;
  final DateTime today;
  final Failure? failure;

  /// La projection de l'état — calculée à chaque émission, pour que les
  /// `buildWhen` comparent ce que l'écran montre et non ce qui le produit.
  final ExpenseRegisterView view;

  const ExpenseRegisterState._({
    required this.status,
    required this.snapshot,
    required this.period,
    required this.query,
    required this.limit,
    required this.today,
    required this.failure,
    required this.view,
  });

  factory ExpenseRegisterState.initial({
    required ExpensePeriod period,
    required DateTime today,
    String? typeFilter,
  }) => ExpenseRegisterState._compute(
    status: ExpenseLoadStatus.initial,
    snapshot: ExpenseRegisterSnapshot.empty,
    period: period,
    query: typeFilter == null
        ? ExpenseQuery.none
        : ExpenseQuery(typeIds: {typeFilter}),
    limit: pageSize,
    today: today,
    failure: null,
  );

  factory ExpenseRegisterState._compute({
    required ExpenseLoadStatus status,
    required ExpenseRegisterSnapshot snapshot,
    required ExpensePeriod period,
    required ExpenseQuery query,
    required int limit,
    required DateTime today,
    required Failure? failure,
  }) => ExpenseRegisterState._(
    status: status,
    snapshot: snapshot,
    period: period,
    query: query,
    limit: limit,
    today: today,
    failure: failure,
    view: ExpenseRegisterView.compute(
      snapshot: snapshot,
      period: period,
      query: query,
      limit: limit,
      today: today,
    ),
  );

  /// Nouvel état, projection recalculée. Le palier revient à 40 dès que le
  /// périmètre change ([resetLimit]) : une pagination ne survit jamais à un
  /// changement de période ou de filtre.
  ExpenseRegisterState copyWith({
    ExpenseLoadStatus? status,
    ExpenseRegisterSnapshot? snapshot,
    ExpensePeriod? period,
    ExpenseQuery? query,
    int? limit,
    DateTime? today,
    Failure? failure,
    bool clearFailure = false,
    bool resetLimit = false,
  }) => ExpenseRegisterState._compute(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    period: period ?? this.period,
    query: query ?? this.query,
    limit: resetLimit ? pageSize : (limit ?? this.limit),
    today: today ?? this.today,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  bool get isLoading =>
      status == ExpenseLoadStatus.initial ||
      status == ExpenseLoadStatus.loading;

  @override
  List<Object?> get props => [
    status,
    snapshot,
    period,
    query,
    limit,
    today,
    failure,
  ];
}
