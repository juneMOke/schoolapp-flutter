import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/level_distribution_item.dart';

class CycleDistributionItem extends Equatable {
  final String cycleId;
  final String cycleCode;
  final int total;
  final List<LevelDistributionItem> levels;

  const CycleDistributionItem({
    required this.cycleId,
    required this.cycleCode,
    required this.total,
    required this.levels,
  });

  @override
  List<Object?> get props => [cycleId, cycleCode, total, levels];
}
