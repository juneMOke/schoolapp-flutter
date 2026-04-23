part of 'finance_bloc.dart';

sealed class FinanceEvent extends Equatable {
  const FinanceEvent();
}

class FinanceFeeTariffsRequested extends FinanceEvent {
  final String levelId;

  const FinanceFeeTariffsRequested({required this.levelId});

  @override
  List<Object?> get props => [levelId];
}
