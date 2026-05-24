import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/level_detail.dart';

class CycleDetail extends Equatable {
  final String cycleId;
  final String cycleCode;
  final int totalStudents;
  final int girls;
  final int boys;
  final List<LevelDetail> levels;

  const CycleDetail({
    required this.cycleId,
    required this.cycleCode,
    required this.totalStudents,
    required this.girls,
    required this.boys,
    required this.levels,
  });

  @override
  List<Object?> get props => [
    cycleId,
    cycleCode,
    totalStudents,
    girls,
    boys,
    levels,
  ];
}
