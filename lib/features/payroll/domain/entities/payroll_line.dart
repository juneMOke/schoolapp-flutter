import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/attendance_summary.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// La retenue d'une avance sur une ligne : le rang de l'échéance, ce qui était
/// dû, ce qui a pu être pris sur le brut, et ce qui glisse au mois suivant.
class PayrollLineAdvance extends Equatable {
  final String advanceId;
  final int rank;
  final int installments;
  final int dueInCents;
  final int takenInCents;
  final int carriedInCents;

  const PayrollLineAdvance({
    required this.advanceId,
    required this.rank,
    required this.installments,
    required this.dueInCents,
    required this.takenInCents,
    required this.carriedInCents,
  });

  @override
  List<Object?> get props => [
    advanceId,
    rank,
    installments,
    dueInCents,
    takenInCents,
    carriedInCents,
  ];
}

/// Une ligne du livre de paie, dans la devise du contrat, en centimes.
///
/// Calculée sur la tablette tant que la paie n'est pas validée ([frozen]
/// faux) ; descendue du serveur ensuite, telle qu'il l'a figée.
class PayrollLine extends Equatable {
  /// Le mois payé, `YYYY-MM`.
  final String month;
  final String staffMemberId;
  final String? contractId;
  final StaffContractKind? contractKind;
  final StaffPayMode? payMode;

  /// Le début du contrat retenu, `YYYY-MM-DD` — « contrat du 15/09 ».
  final String? contractFrom;
  final String currency;
  final int baseInCents;

  /// Vacataire à l'heure : les minutes pointées, le taux et leur mois.
  final int? baseMinutes;
  final int? baseRateInCents;
  final String? hoursMonth;
  final int overtimeMinutes;
  final int overtimeRateInCents;
  final int overtimeInCents;
  final int children;
  final int allowanceInCents;
  final int grossInCents;
  final List<PayrollLineAdvance> advances;
  final int netInCents;

  /// Le Pointage du mois précédent, clos — indicatif, sans retenue.
  final String? attendanceMonth;
  final AttendanceAgentSummary attendance;
  final bool frozen;

  const PayrollLine({
    required this.month,
    required this.staffMemberId,
    required this.currency,
    required this.baseInCents,
    required this.grossInCents,
    required this.netInCents,
    this.contractId,
    this.contractKind,
    this.payMode,
    this.contractFrom,
    this.baseMinutes,
    this.baseRateInCents,
    this.hoursMonth,
    this.overtimeMinutes = 0,
    this.overtimeRateInCents = 0,
    this.overtimeInCents = 0,
    this.children = 0,
    this.allowanceInCents = 0,
    this.advances = const [],
    this.attendanceMonth,
    this.attendance = AttendanceAgentSummary.zero,
    this.frozen = false,
  });

  /// La même ligne, complétée de ce que le contrat retenu dit d'elle quand le
  /// serveur ne l'a pas redit.
  PayrollLine withContract({
    StaffContractKind? kind,
    StaffPayMode? payMode,
    String? from,
  }) => PayrollLine(
    month: month,
    staffMemberId: staffMemberId,
    contractId: contractId,
    contractKind: contractKind ?? kind,
    payMode: this.payMode ?? payMode,
    contractFrom: contractFrom ?? from,
    currency: currency,
    baseInCents: baseInCents,
    baseMinutes: baseMinutes,
    baseRateInCents: baseRateInCents,
    hoursMonth: hoursMonth,
    overtimeMinutes: overtimeMinutes,
    overtimeRateInCents: overtimeRateInCents,
    overtimeInCents: overtimeInCents,
    children: children,
    allowanceInCents: allowanceInCents,
    grossInCents: grossInCents,
    advances: advances,
    netInCents: netInCents,
    attendanceMonth: attendanceMonth,
    attendance: attendance,
    frozen: frozen,
  );

  int get advanceInCents =>
      advances.fold(0, (sum, advance) => sum + advance.takenInCents);

  int get carriedInCents =>
      advances.fold(0, (sum, advance) => sum + advance.carriedInCents);

  /// Heures sup. et allocations.
  int get complementsInCents => overtimeInCents + allowanceInCents;

  bool get isHourly => payMode == StaffPayMode.hourly;

  bool get overtimeAllowed => contractKind != StaffContractKind.vacataire;

  @override
  List<Object?> get props => [
    month,
    staffMemberId,
    contractId,
    contractKind,
    payMode,
    contractFrom,
    currency,
    baseInCents,
    baseMinutes,
    baseRateInCents,
    hoursMonth,
    overtimeMinutes,
    overtimeRateInCents,
    overtimeInCents,
    children,
    allowanceInCents,
    grossInCents,
    advances,
    netInCents,
    attendanceMonth,
    attendance,
    frozen,
  ];
}
