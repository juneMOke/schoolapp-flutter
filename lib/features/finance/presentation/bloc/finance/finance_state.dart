part of 'finance_bloc.dart';

enum FinanceStatus { initial, loading, success, failure }

// Sentinel pour les champs nullable dans copyWith
const _undefined = Object();

class FinanceState extends Equatable {
  final FinanceStatus status;
  final List<FeeTariff> tariffs;
  final String? errorMessage;

  const FinanceState({
    this.status = FinanceStatus.initial,
    this.tariffs = const [],
    this.errorMessage,
  });

  FinanceState copyWith({
    FinanceStatus? status,
    List<FeeTariff>? tariffs,
    Object? errorMessage = _undefined,
  }) =>
      FinanceState(
        status: status ?? this.status,
        tariffs: tariffs ?? this.tariffs,
        errorMessage: identical(errorMessage, _undefined)
            ? this.errorMessage
            : errorMessage as String?,
      );

  @override
  List<Object?> get props => [status, tariffs, errorMessage];
}
