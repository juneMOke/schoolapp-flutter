import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';

part 'fee_tariff_model.g.dart';

@JsonSerializable()
class FeeTariffModel extends Equatable {
  final String id;
  final String label;
  final double amount;
  final String currency;
  final String levelId;

  const FeeTariffModel({
    required this.id,
    required this.label,
    required this.amount,
    required this.currency,
    required this.levelId,
  });

  factory FeeTariffModel.fromJson(Map<String, dynamic> json) =>
      _$FeeTariffModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeeTariffModelToJson(this);

  FeeTariff toEntity() => FeeTariff(
    id: id,
    label: label,
    amount: amount,
    currency: currency,
    levelId: levelId,
  );

  @override
  List<Object?> get props => [id, label, amount, currency, levelId];
}
