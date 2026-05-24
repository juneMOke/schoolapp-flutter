import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/cycle_detail_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'school_detail_model.g.dart';

@JsonSerializable()
class SchoolDetailModel extends Equatable {
  final int totalStudents;
  final int girls;
  final int boys;
  final List<CycleDetailModel> cycles;

  const SchoolDetailModel({
    required this.totalStudents,
    required this.girls,
    required this.boys,
    required this.cycles,
  });

  factory SchoolDetailModel.fromJson(Map<String, dynamic> json) =>
      _$SchoolDetailModelFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolDetailModelToJson(this);

  SchoolDetail toEntity() => SchoolDetail(
    totalStudents: totalStudents,
    girls: girls,
    boys: boys,
    cycles: cycles.map((cycle) => cycle.toEntity()).toList(growable: false),
  );

  @override
  List<Object?> get props => [totalStudents, girls, boys, cycles];
}
