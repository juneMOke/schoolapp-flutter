import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'classroom_kpis_model.g.dart';

@JsonSerializable()
class ClassroomKpisModel extends Equatable {
  final int totalActive;
  final int activeGirls;
  final int activeBoys;
  final int inactive;

  const ClassroomKpisModel({
    required this.totalActive,
    required this.activeGirls,
    required this.activeBoys,
    required this.inactive,
  });

  factory ClassroomKpisModel.fromJson(Map<String, dynamic> json) =>
      _$ClassroomKpisModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassroomKpisModelToJson(this);

  ClassroomKpis toEntity() => ClassroomKpis(
    totalActive: totalActive,
    activeGirls: activeGirls,
    activeBoys: activeBoys,
    inactive: inactive,
  );

  @override
  List<Object?> get props => [totalActive, activeGirls, activeBoys, inactive];
}
