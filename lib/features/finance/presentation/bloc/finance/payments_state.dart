part of 'payments_bloc.dart';

const _undefined = Object();

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
  final PaymentsStatus createStatus;
  final PaymentsErrorType createErrorType;
  final Payment? createdPayment;
  final PaymentsStatus allocationsStatus;
  final Map<String, List<PaymentAllocation>> allocationsByPaymentId;
  final PaymentsErrorType allocationsErrorType;

  const PaymentsState({
    this.status = PaymentsStatus.initial,
    this.payments = const [],
    this.errorType = PaymentsErrorType.none,
    this.createStatus = PaymentsStatus.initial,
    this.createErrorType = PaymentsErrorType.none,
    this.createdPayment,
    this.allocationsStatus = PaymentsStatus.initial,
    this.allocationsByPaymentId = const {},
    this.allocationsErrorType = PaymentsErrorType.none,
  });

  PaymentsState copyWith({
    PaymentsStatus? status,
    List<Payment>? payments,
    PaymentsErrorType? errorType,
    PaymentsStatus? createStatus,
    PaymentsErrorType? createErrorType,
    Object? createdPayment = _undefined,
    PaymentsStatus? allocationsStatus,
    Map<String, List<PaymentAllocation>>? allocationsByPaymentId,
    PaymentsErrorType? allocationsErrorType,
  }) => PaymentsState(
    status: status ?? this.status,
    payments: payments ?? this.payments,
    errorType: errorType ?? this.errorType,
    createStatus: createStatus ?? this.createStatus,
    createErrorType: createErrorType ?? this.createErrorType,
    createdPayment: identical(createdPayment, _undefined)
        ? this.createdPayment
        : createdPayment as Payment?,
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
    createStatus,
    createErrorType,
    createdPayment,
    allocationsStatus,
    allocationsByPaymentId,
    allocationsErrorType,
  ];
}