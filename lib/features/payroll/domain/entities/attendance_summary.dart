import 'package:equatable/equatable.dart';

/// Ce que le Pointage d'un mois clos dit d'un agent : les minutes réellement
/// pointées et les compteurs. Un agent absent du résumé vaut [zero].
class AttendanceAgentSummary extends Equatable {
  final int workedMinutes;
  final int unjustifiedAbsences;
  final int justifiedAbsences;
  final int lates;
  final int lateMinutes;

  const AttendanceAgentSummary({
    this.workedMinutes = 0,
    this.unjustifiedAbsences = 0,
    this.justifiedAbsences = 0,
    this.lates = 0,
    this.lateMinutes = 0,
  });

  static const AttendanceAgentSummary zero = AttendanceAgentSummary();

  @override
  List<Object?> get props => [
    workedMinutes,
    unjustifiedAbsences,
    justifiedAbsences,
    lates,
    lateMinutes,
  ];
}

/// Le résumé d'un mois clos du Pointage, immuable une fois descendu.
class AttendanceSummary extends Equatable {
  /// `YYYY-MM`.
  final String month;
  final String? closedAt;
  final Map<String, AttendanceAgentSummary> agents;

  const AttendanceSummary({
    required this.month,
    required this.agents,
    this.closedAt,
  });

  AttendanceAgentSummary of(String staffMemberId) =>
      agents[staffMemberId] ?? AttendanceAgentSummary.zero;

  @override
  List<Object?> get props => [month, closedAt, agents];
}
