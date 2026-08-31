part of 'boutique_history_bloc.dart';

enum HistoryStatus { initial, loading, ready, failure }

class BoutiqueHistoryState extends Equatable {
  final HistoryStatus status;

  /// La caisse du jour par défaut : c'est ce qu'on vient vérifier.
  final SalesHistoryPeriod period;

  final List<SaleHistoryEntry> sales;
  final Failure? failure;

  const BoutiqueHistoryState({
    this.status = HistoryStatus.initial,
    this.period = SalesHistoryPeriod.day,
    this.sales = const [],
    this.failure,
  });

  /// Le total de la fenêtre, **par devise**.
  ///
  /// Jamais une somme unique : additionner des dollars et des francs donnerait
  /// un nombre qui ne veut rien dire, et un guichet le lirait comme un montant.
  MoneyBag get totalsByCurrency =>
      sales.fold(MoneyBag.empty, (bag, sale) => bag + sale.amounts);

  /// Combien de ventes attendent encore de partir — ce que le guichet doit
  /// savoir avant d'éteindre la tablette.
  int get pendingCount => sales.where((sale) => sale.isPending).length;

  BoutiqueHistoryState copyWith({
    HistoryStatus? status,
    SalesHistoryPeriod? period,
    List<SaleHistoryEntry>? sales,
    Failure? failure,
    bool clearFailure = false,
  }) => BoutiqueHistoryState(
    status: status ?? this.status,
    period: period ?? this.period,
    sales: sales ?? this.sales,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [status, period, sales, failure];
}
