import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/level_distribution_item_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'cycle_distribution_item_model.g.dart';

@JsonSerializable()
class CycleDistributionItemModel extends Equatable {
  final String cycleId;
  final String cycleCode;
  final int total;
  final List<LevelDistributionItemModel> levels;

  const CycleDistributionItemModel({
    required this.cycleId,
    required this.cycleCode,
    required this.total,
    required this.levels,
  });

  factory CycleDistributionItemModel.fromJson(Map<String, dynamic> json) =>
      _$CycleDistributionItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$CycleDistributionItemModelToJson(this);

  CycleDistributionItem toEntity() => CycleDistributionItem(
    cycleId: cycleId,
    cycleCode: cycleCode,
    total: total,
    levels: levels.map((level) => level.toEntity()).toList(growable: false),
  );

  @override
  List<Object?> get props => [cycleId, cycleCode, total, levels];
}
