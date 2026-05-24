import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/classroom_item_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'level_detail_model.g.dart';

@JsonSerializable()
class LevelDetailModel extends Equatable {
  final String levelId;
  final String levelCode;
  final int totalStudents;
  final int girls;
  final int boys;
  final List<ClassroomItemModel> classrooms;

  const LevelDetailModel({
    required this.levelId,
    required this.levelCode,
    required this.totalStudents,
    required this.girls,
    required this.boys,
    required this.classrooms,
  });

  factory LevelDetailModel.fromJson(Map<String, dynamic> json) =>
      _$LevelDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$LevelDetailModelToJson(this);

  LevelDetail toEntity() => LevelDetail(
    levelId: levelId,
    levelCode: levelCode,
    totalStudents: totalStudents,
    girls: girls,
    boys: boys,
    classrooms: classrooms
        .map((classroom) => classroom.toEntity())
        .toList(growable: false),
  );

  @override
  List<Object?> get props => [
    levelId,
    levelCode,
    totalStudents,
    girls,
    boys,
    classrooms,
  ];
}
