import 'package:equatable/equatable.dart';

/// Ligne du tableau de presence par classe (ordonne par niveau cote backend).
class ClassAttendanceStat extends Equatable {
  final String cycle;
  final String level;
  final String classroomId;
  final String className;
  final double presenceRate;
  final double justifiedAbsenceRate;
  final double unjustifiedAbsenceRate;
  final int recordedDays;

  const ClassAttendanceStat({
    required this.cycle,
    required this.level,
    required this.classroomId,
    required this.className,
    required this.presenceRate,
    required this.justifiedAbsenceRate,
    required this.unjustifiedAbsenceRate,
    required this.recordedDays,
  });

  @override
  List<Object?> get props => [
    cycle,
    level,
    classroomId,
    className,
    presenceRate,
    justifiedAbsenceRate,
    unjustifiedAbsenceRate,
    recordedDays,
  ];
}
