import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';

/// L'état d'une avance au serveur (`AdvanceProgress`, celui du pull).
enum PayrollAdvancePhase {
  upcoming('UPCOMING'),
  inProgress('IN_PROGRESS'),
  carried('CARRIED'),
  settled('SETTLED'),
  cancelled('CANCELLED');

  const PayrollAdvancePhase(this.wire);
  final String wire;

  static PayrollAdvancePhase fromWire(String? value) => values.firstWhere(
    (phase) => phase.wire == value,
    orElse: () => inProgress,
  );

  /// Encore à retenir.
  bool get isOngoing =>
      this == upcoming || this == inProgress || this == carried;
}

/// Une avance ou un prêt du tableau de bord : vivante, ou soldée dans le mois
/// affiché.
class PayrollDashboardAdvance extends Equatable {
  final String advanceId;
  final String staffMemberId;
  final String fullName;

  /// Une avance se retient en une échéance ; un prêt, en plusieurs.
  final bool isLoan;
  final int installments;
  final SalaryAdvanceReason? reason;
  final String? reasonDetail;

  /// `YYYY-MM-DD`.
  final String grantedOn;
  final int amountInCents;
  final String currency;
  final int remainingInCents;
  final int takenThisMonthInCents;
  final PayrollAdvancePhase phase;

  const PayrollDashboardAdvance({
    required this.advanceId,
    required this.staffMemberId,
    required this.fullName,
    required this.grantedOn,
    required this.amountInCents,
    required this.currency,
    this.isLoan = false,
    this.installments = 1,
    this.reason,
    this.reasonDetail,
    this.remainingInCents = 0,
    this.takenThisMonthInCents = 0,
    this.phase = PayrollAdvancePhase.inProgress,
  });

  /// La part remboursée, de 0 à 1.
  double get repaidShare => amountInCents <= 0
      ? 0
      : ((amountInCents - remainingInCents) / amountInCents).clamp(0, 1);

  @override
  List<Object?> get props => [
    advanceId,
    staffMemberId,
    fullName,
    isLoan,
    installments,
    reason,
    reasonDetail,
    grantedOn,
    amountInCents,
    currency,
    remainingInCents,
    takenThisMonthInCents,
    phase,
  ];
}
