part of 'boutique_history_bloc.dart';

sealed class BoutiqueHistoryEvent extends Equatable {
  const BoutiqueHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Première lecture, et rechargement après un encaissement.
class BoutiqueHistoryRequested extends BoutiqueHistoryEvent {
  final String academicYearId;

  const BoutiqueHistoryRequested(this.academicYearId);

  @override
  List<Object?> get props => [academicYearId];
}

class BoutiqueHistoryPeriodChanged extends BoutiqueHistoryEvent {
  final String academicYearId;
  final SalesHistoryPeriod period;

  const BoutiqueHistoryPeriodChanged({
    required this.academicYearId,
    required this.period,
  });

  @override
  List<Object?> get props => [academicYearId, period];
}
