import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/cycle_detail.dart';

class SchoolDetail extends Equatable {
  final int totalStudents;
  final int girls;
  final int boys;
  final List<CycleDetail> cycles;

  const SchoolDetail({
    required this.totalStudents,
    required this.girls,
    required this.boys,
    required this.cycles,
  });

  @override
  List<Object?> get props => [totalStudents, girls, boys, cycles];
}
