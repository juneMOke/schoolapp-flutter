import 'package:equatable/equatable.dart';

/// Indicateurs cles de presence a l'echelle de l'ecole sur une periode.
///
/// Les trois taux (presence / absence justifiee / absence injustifiee)
/// totalisent 100 %.
class AttendanceKpis extends Equatable {
  final double presenceRate;
  final double justifiedAbsenceRate;
  final double unjustifiedAbsenceRate;
  final int recordedDays;
  final int presentDays;
  final int justifiedAbsenceDays;
  final int unjustifiedAbsenceDays;

  const AttendanceKpis({
    required this.presenceRate,
    required this.justifiedAbsenceRate,
    required this.unjustifiedAbsenceRate,
    required this.recordedDays,
    required this.presentDays,
    required this.justifiedAbsenceDays,
    required this.unjustifiedAbsenceDays,
  });

  @override
  List<Object?> get props => [
    presenceRate,
    justifiedAbsenceRate,
    unjustifiedAbsenceRate,
    recordedDays,
    presentDays,
    justifiedAbsenceDays,
    unjustifiedAbsenceDays,
  ];
}
