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
  final PaymentsStatus allocationsStatus;
  final Map<String, List<PaymentAllocation>> allocationsByPaymentId;
  final PaymentsErrorType allocationsErrorType;

  const PaymentsState({
    this.status = PaymentsStatus.initial,
    this.payments = const [],
    this.errorType = PaymentsErrorType.none,
    this.allocationsStatus = PaymentsStatus.initial,
    this.allocationsByPaymentId = const {},
    this.allocationsErrorType = PaymentsErrorType.none,
  });

  PaymentsState copyWith({
    PaymentsStatus? status,
    List<Payment>? payments,
    PaymentsErrorType? errorType,
    PaymentsStatus? allocationsStatus,
    Map<String, List<PaymentAllocation>>? allocationsByPaymentId,
    PaymentsErrorType? allocationsErrorType,
  }) => PaymentsState(
    status: status ?? this.status,
    payments: payments ?? this.payments,
    errorType: errorType ?? this.errorType,
    allocationsStatus: allocationsStatus ?? this.allocationsStatus,
    allocationsByPaymentId:
        allocationsByPaymentId ?? this.allocationsByPaymentId,
    allocationsErrorType: allocationsErrorType ?? this.allocationsErrorType,
  );

  @override
  List<Object?> get props => [
    status,
    payments,
    errorType,
    allocationsStatus,
    allocationsByPaymentId,
    allocationsErrorType,
  ];
}