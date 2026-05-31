import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/classroom_detail_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/classroom_kpis_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/classroom_stats_context_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model/cycle_distribution_item_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'classroom_stats_response_model.g.dart';

@JsonSerializable()
class ClassroomStatsResponseModel extends Equatable {
  final ClassroomStatsContextModel context;
  final ClassroomKpisModel kpis;
  final List<CycleDistributionItemModel> distributionByCycle;
  final ClassroomDetailModel detail;

  const ClassroomStatsResponseModel({
    required this.context,
    required this.kpis,
    required this.distributionByCycle,
    required this.detail,
  });

  factory ClassroomStatsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ClassroomStatsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClassroomStatsResponseModelToJson(this);

  ClassroomStats toEntity() => ClassroomStats(
    context: context.toEntity(),
    kpis: kpis.toEntity(),
    distributionByCycle: distributionByCycle
        .map((item) => item.toEntity())
        .toList(growable: false),
    detail: detail.toEntity(),
  );

  @override
  List<Object?> get props => [context, kpis, distributionByCycle, detail];
}
