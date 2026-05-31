import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/fee_type_item_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/fee_type_distribution.dart';

class FeeTypeDistributionModel {
  final List<FeeTypeItemModel> items;

  const FeeTypeDistributionModel({required this.items});

  factory FeeTypeDistributionModel.fromJson(Map<String, dynamic> json) {
    return FeeTypeDistributionModel(
      items: (json['items'] as List<dynamic>)
          .map(
            (item) => FeeTypeItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };

  FeeTypeDistribution toEntity() => FeeTypeDistribution(
    items: items.map((item) => item.toEntity()).toList(growable: false),
  );
}
