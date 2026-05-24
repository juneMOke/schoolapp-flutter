import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/classroom_detail.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/classroom_kpis.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/classroom_stats_context.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats/cycle_distribution_item.dart';

class ClassroomStats extends Equatable {
  final ClassroomStatsContext context;
  final ClassroomKpis kpis;
  final List<CycleDistributionItem> distributionByCycle;
  final ClassroomDetail detail;

  const ClassroomStats({
    required this.context,
    required this.kpis,
    required this.distributionByCycle,
    required this.detail,
  });

  @override
  List<Object?> get props => [context, kpis, distributionByCycle, detail];
}
