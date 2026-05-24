import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/fee_type_item.dart';

class FeeTypeDistribution extends Equatable {
  final List<FeeTypeItem> items;

  const FeeTypeDistribution({required this.items});

  @override
  List<Object?> get props => [items];
}
