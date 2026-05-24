import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/school_detail_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'classroom_detail_model.g.dart';

@JsonSerializable()
class ClassroomDetailModel extends Equatable {
  final SchoolDetailModel school;

  const ClassroomDetailModel({required this.school});

  factory ClassroomDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ClassroomDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassroomDetailModelToJson(this);

  ClassroomDetail toEntity() => ClassroomDetail(school: school.toEntity());

  @override
  List<Object?> get props => [school];
}
