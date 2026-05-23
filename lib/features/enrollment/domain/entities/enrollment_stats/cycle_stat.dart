import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/level_stat.dart';

class CycleStat extends Equatable {
  final String code;
  final int total;
  final List<LevelStat> levels;

  const CycleStat({
    required this.code,
    required this.total,
    required this.levels,
  });

  @override
  List<Object?> get props => [code, total, levels];
}
