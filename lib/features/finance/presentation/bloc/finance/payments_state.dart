part of 'payments_bloc.dart';

enum PaymentsStatus { initial, loading, success, failure }

enum PaymentsErrorType {
  none,
  network,
  notFound,
  validation,
  unauthorized,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}

class PaymentsState extends Equatable {
  final PaymentsStatus status;
  final List<Payment> payments;
  final PaymentsErrorType errorType;

  const PaymentsState({
    this.status = PaymentsStatus.initial,
    this.payments = const [],
    this.errorType = PaymentsErrorType.none,
  });

  PaymentsState copyWith({
    PaymentsStatus? status,
    List<Payment>? payments,
    PaymentsErrorType? errorType,
  }) => PaymentsState(
    status: status ?? this.status,
    payments: payments ?? this.payments,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, payments, errorType];
}