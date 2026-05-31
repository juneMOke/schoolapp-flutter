import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'classroom_stats_context_model.g.dart';

@JsonSerializable()
class ClassroomStatsContextModel extends Equatable {
  final String academicYearId;
  final String academicYearName;
  final DateTime generatedAt;

  const ClassroomStatsContextModel({
    required this.academicYearId,
    required this.academicYearName,
    required this.generatedAt,
  });

  factory ClassroomStatsContextModel.fromJson(Map<String, dynamic> json) =>
      _$ClassroomStatsContextModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassroomStatsContextModelToJson(this);

  ClassroomStatsContext toEntity() => ClassroomStatsContext(
    academicYearId: academicYearId,
    academicYearName: academicYearName,
    generatedAt: generatedAt,
  );

  @override
  List<Object?> get props => [academicYearId, academicYearName, generatedAt];
}
