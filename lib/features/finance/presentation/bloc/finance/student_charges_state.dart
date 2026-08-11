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

  /// Flux BROUILLON seulement : la grille tarifaire est absente de cet appareil
  /// pour l'année visée, donc une liste de créances vide ne veut pas dire
  /// « rien à payer ». Le wizard bloque et le dit, plutôt que d'annoncer 0 F.
  final bool feeGridUnavailable;

  const StudentChargesState({
    this.status = StudentChargesStatus.initial,
    this.studentCharges = const [],
    this.errorType = StudentChargesErrorType.none,
    this.allocationsStatus = StudentChargesStatus.initial,
    this.allocationsByChargeId = const {},
    this.allocationsErrorType = StudentChargesErrorType.none,
    this.updatingChargeId,
    this.feeGridUnavailable = false,
  });

  StudentChargesState copyWith({
    StudentChargesStatus? status,
    List<StudentCharge>? studentCharges,
    StudentChargesErrorType? errorType,
    StudentChargesStatus? allocationsStatus,
    Map<String, List<PaymentAllocation>>? allocationsByChargeId,
    StudentChargesErrorType? allocationsErrorType,
    bool? feeGridUnavailable,
    Object? updatingChargeId = _undefined,
  }) => StudentChargesState(
    status: status ?? this.status,
    studentCharges: studentCharges ?? this.studentCharges,
    errorType: errorType ?? this.errorType,
    allocationsStatus: allocationsStatus ?? this.allocationsStatus,
    allocationsByChargeId: allocationsByChargeId ?? this.allocationsByChargeId,
    allocationsErrorType: allocationsErrorType ?? this.allocationsErrorType,
    updatingChargeId: identical(updatingChargeId, _undefined)
        ? this.updatingChargeId
        : updatingChargeId as String?,
    feeGridUnavailable: feeGridUnavailable ?? this.feeGridUnavailable,
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
    feeGridUnavailable,
  ];
}
