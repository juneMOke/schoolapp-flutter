import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'classroom_item_model.g.dart';

@JsonSerializable()
class ClassroomItemModel extends Equatable {
  final String classroomId;
  final String name;
  final int totalStudents;
  final int girls;
  final int boys;

  const ClassroomItemModel({
    required this.classroomId,
    required this.name,
    required this.totalStudents,
    required this.girls,
    required this.boys,
  });

  factory ClassroomItemModel.fromJson(Map<String, dynamic> json) =>
      _$ClassroomItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassroomItemModelToJson(this);

  ClassroomItem toEntity() => ClassroomItem(
    classroomId: classroomId,
    name: name,
    totalStudents: totalStudents,
    girls: girls,
    boys: boys,
  );

  @override
  List<Object?> get props => [classroomId, name, totalStudents, girls, boys];
}
