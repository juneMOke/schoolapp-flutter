import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';

/// L'état serveur d'une paie mensuelle, tel que le flux l'a donné.
class PayrollHeader extends Equatable {
  final String id;

  /// `YYYY-MM`.
  final String month;
  final PayrollStatus status;
  final String? submittedAt;
  final String? submittedBy;
  final String? validatedAt;
  final String? validatedBy;
  final String? returnReason;

  /// Le VALIDATE en vigueur ; `null` hors [PayrollStatus.validated].
  final String? validationGestureId;

  const PayrollHeader({
    required this.id,
    required this.month,
    required this.status,
    this.submittedAt,
    this.submittedBy,
    this.validatedAt,
    this.validatedBy,
    this.returnReason,
    this.validationGestureId,
  });

  @override
  List<Object?> get props => [
    id,
    month,
    status,
    submittedAt,
    submittedBy,
    validatedAt,
    validatedBy,
    returnReason,
    validationGestureId,
  ];
}
