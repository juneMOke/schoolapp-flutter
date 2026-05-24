import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/level_detail_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'cycle_detail_model.g.dart';

@JsonSerializable()
class CycleDetailModel extends Equatable {
  final String cycleId;
  final String cycleCode;
  final int totalStudents;
  final int girls;
  final int boys;
  final List<LevelDetailModel> levels;

  const CycleDetailModel({
    required this.cycleId,
    required this.cycleCode,
    required this.totalStudents,
    required this.girls,
    required this.boys,
    required this.levels,
  });

  factory CycleDetailModel.fromJson(Map<String, dynamic> json) =>
      _$CycleDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$CycleDetailModelToJson(this);

  CycleDetail toEntity() => CycleDetail(
    cycleId: cycleId,
    cycleCode: cycleCode,
    totalStudents: totalStudents,
    girls: girls,
    boys: boys,
    levels: levels.map((level) => level.toEntity()).toList(growable: false),
  );

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
