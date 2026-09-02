import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_fee_code_amount_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_imputation.dart';

/// Miroir de `TillImputationDto` — ce que les versements de la fenêtre ont
/// éteint dans une devise de **créance**.
class TillImputationModel {
  final String currency;
  final int total;
  final List<TillFeeCodeAmountModel> byFeeCode;

  const TillImputationModel({
    required this.currency,
    required this.total,
    required this.byFeeCode,
  });

  /// **Le total ne cède pas, la ventilation cède.** Un bloc d'imputation sans
  /// son total ne se répare pas en sommant ses lignes : les deux viennent de la
  /// même requête, et fabriquer l'un depuis l'autre masquerait précisément le
  /// jour où ils divergent. Les lignes, elles, sont le détail du chiffre.
  factory TillImputationModel.fromJson(Map<String, dynamic> json) {
    return TillImputationModel(
      // Normalisée, jamais refusée : même règle que partout ailleurs.
      currency: ((json['currency'] as String?) ?? '').trim().toUpperCase(),
      total: (json['total'] as num).toInt(),
      byFeeCode: [
        for (final raw in (json['byFeeCode'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>) TillFeeCodeAmountModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'total': total,
    'byFeeCode': byFeeCode.map((line) => line.toJson()).toList(growable: false),
  };

  TillImputation toEntity() => TillImputation(
    currency: currency,
    total: total,
    byFeeCode: byFeeCode.map((line) => line.toEntity()).toList(growable: false),
  );
}
