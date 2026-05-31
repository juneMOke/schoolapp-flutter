import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/fee_type_item.dart';

class FeeTypeItemModel {
  final String code;
  final int collected;
  final int expected;
  final int collectionRate;

  const FeeTypeItemModel({
    required this.code,
    required this.collected,
    required this.expected,
    required this.collectionRate,
  });

  factory FeeTypeItemModel.fromJson(Map<String, dynamic> json) {
    return FeeTypeItemModel(
      code: json['code'] as String,
      collected: (json['collected'] as num).toInt(),
      expected: (json['expected'] as num).toInt(),
      collectionRate: (json['collectionRate'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'collected': collected,
    'expected': expected,
    'collectionRate': collectionRate,
  };

  FeeTypeItem toEntity() => FeeTypeItem(
    code: code,
    collected: collected,
    expected: expected,
    collectionRate: collectionRate,
  );
}
