part of 'student_charges_bloc.dart';

const _undefined = Object();

enum StudentChargesStatus { initial, loading, success, failure }

enum StudentChargesErrorType {
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

class StudentChargesState extends Equatable {
  final StudentChargesStatus status;
  final List<StudentCharge> studentCharges;
  final StudentChargesErrorType errorType;
  final StudentChargesStatus allocationsStatus;
  final Map<String, List<PaymentAllocation>> allocationsByChargeId;
  final StudentChargesErrorType allocationsErrorType;
  final String? updatingChargeId;

  const StudentChargesState({
    this.status = StudentChargesStatus.initial,
    this.studentCharges = const [],
    this.errorType = StudentChargesErrorType.none,
    this.allocationsStatus = StudentChargesStatus.initial,
    this.allocationsByChargeId = const {},
    this.allocationsErrorType = StudentChargesErrorType.none,
    this.updatingChargeId,
  });

  StudentChargesState copyWith({
    StudentChargesStatus? status,
    List<StudentCharge>? studentCharges,
    StudentChargesErrorType? errorType,
    StudentChargesStatus? allocationsStatus,
    Map<String, List<PaymentAllocation>>? allocationsByChargeId,
    StudentChargesErrorType? allocationsErrorType,
    Object? updatingChargeId = _undefined,
  }) => StudentChargesState(
    status: status ?? this.status,
    studentCharges: studentCharges ?? this.studentCharges,
    errorType: errorType ?? this.errorType,
    allocationsStatus: allocationsStatus ?? this.allocationsStatus,
    allocationsByChargeId: allocationsByChargeId ?? this.allocationsByChargeId,
    allocationsErrorType:
        allocationsErrorType ?? this.allocationsErrorType,
    updatingChargeId: identical(updatingChargeId, _undefined)
        ? this.updatingChargeId
        : updatingChargeId as String?,
  );

  @override
  List<Object?> get props => [
    status,
    studentCharges,
    errorType,
    allocationsStatus,
    allocationsByChargeId,
    allocationsErrorType,
    updatingChargeId,
  ];
}
