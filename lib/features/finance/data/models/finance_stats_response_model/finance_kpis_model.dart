import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_kpis.dart';

class FinanceKpisModel {
  final int collected;
  final int expected;
  final int outstanding;
  final int collectionRate;

  const FinanceKpisModel({
    required this.collected,
    required this.expected,
    required this.outstanding,
    required this.collectionRate,
  });

  factory FinanceKpisModel.fromJson(Map<String, dynamic> json) {
    return FinanceKpisModel(
      collected: (json['collected'] as num).toInt(),
      expected: (json['expected'] as num).toInt(),
      outstanding: (json['outstanding'] as num).toInt(),
      collectionRate: (json['collectionRate'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'collected': collected,
    'expected': expected,
    'outstanding': outstanding,
    'collectionRate': collectionRate,
  };

  FinanceKpis toEntity() => FinanceKpis(
    collected: collected,
    expected: expected,
    outstanding: outstanding,
    collectionRate: collectionRate,
  );
}
