import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_fee_code_amount.dart';

/// Miroir de `TillFeeCodeAmountDto`.
class TillFeeCodeAmountModel {
  final String code;

  /// Tel qu'il descend du fil, sans repli — c'est [toEntity] qui décide quoi
  /// montrer si le serveur n'envoie rien.
  final String label;

  final int amount;

  const TillFeeCodeAmountModel({
    required this.code,
    required this.label,
    required this.amount,
  });

  factory TillFeeCodeAmountModel.fromJson(Map<String, dynamic> json) {
    return TillFeeCodeAmountModel(
      code: ((json['code'] as String?) ?? '').trim(),
      label: ((json['label'] as String?) ?? '').trim(),
      amount: (json['amount'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'label': label,
    'amount': amount,
  };

  TillFeeCodeAmount toEntity() => TillFeeCodeAmount(
    code: code,
    label: label.isEmpty ? code : label,
    amount: amount,
  );
}
