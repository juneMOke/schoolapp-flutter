import 'package:equatable/equatable.dart';

/// Classe figurant dans le top 5 des plus absentes (par taux d'absence).
class TopAbsentClass extends Equatable {
  final String classroomId;
  final String className;
  final String level;
  final double absenceRate;
  final int absenceDays;

  const TopAbsentClass({
    required this.classroomId,
    required this.className,
    required this.level,
    required this.absenceRate,
    required this.absenceDays,
  });

  @override
  List<Object?> get props => [
    classroomId,
    className,
    level,
    absenceRate,
    absenceDays,
  ];
}
