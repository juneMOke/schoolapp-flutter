import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard_filter.dart';

/// Une ligne « Ce que chaque salarié perçoit » — celle de la situation de
/// paie (SP), dans la devise de sa section.
class PayrollDashboardRow extends Equatable {
  final String staffMemberId;
  final String fullName;
  final String? jobTitle;

  /// Le brut du mois.
  final int plannedInCents;

  /// Absence, IPR, CNSS, PC/E et échéances d'avance.
  final int deductionsInCents;
  final int netInCents;

  /// Ce qui reste dû sur les paies validées d'avant, dans cette devise.
  final int arrearsInCents;

  /// Les versements vivants du mois sur la ligne.
  final int receivedInCents;

  /// Net + arriérés − perçu.
  final int remainingInCents;
  final PayrollDashboardStatus status;

  const PayrollDashboardRow({
    required this.staffMemberId,
    required this.fullName,
    this.jobTitle,
    this.plannedInCents = 0,
    this.deductionsInCents = 0,
    this.netInCents = 0,
    this.arrearsInCents = 0,
    this.receivedInCents = 0,
    this.remainingInCents = 0,
    this.status = PayrollDashboardStatus.due,
  });

  @override
  List<Object?> get props => [
    staffMemberId,
    fullName,
    jobTitle,
    plannedInCents,
    deductionsInCents,
    netInCents,
    arrearsInCents,
    receivedInCents,
    remainingInCents,
    status,
  ];
}
