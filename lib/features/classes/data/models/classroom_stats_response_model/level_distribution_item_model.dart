import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';

part 'level_distribution_item_model.g.dart';

@JsonSerializable()
class LevelDistributionItemModel extends Equatable {
  final String levelId;
  final String levelCode;
  final int total;

  const LevelDistributionItemModel({
    required this.levelId,
    required this.levelCode,
    required this.total,
  });

  factory LevelDistributionItemModel.fromJson(Map<String, dynamic> json) =>
      _$LevelDistributionItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$LevelDistributionItemModelToJson(this);

  LevelDistributionItem toEntity() => LevelDistributionItem(
    levelId: levelId,
    levelCode: levelCode,
    total: total,
  );

  @override
  List<Object?> get props => [levelId, levelCode, total];
}
