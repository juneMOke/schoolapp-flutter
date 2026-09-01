import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_fee_code_amount_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_summary.dart';

/// Miroir de `TillSummaryDto` — le chiffre de l'écran.
class TillSummaryModel {
  final int total;
  final int fees;
  final int boutique;
  final List<TillFeeCodeAmountModel> byFeeCode;

  const TillSummaryModel({
    required this.total,
    required this.fees,
    required this.boutique,
    required this.byFeeCode,
  });

  /// **Aucune tolérance sur les trois montants.** Un résumé absent lève, et
  /// l'écran passe à l'erreur : un repli à zéro dirait « rien n'est entré
  /// aujourd'hui » à un caissier qui a le tiroir ouvert devant lui.
  ///
  /// La ventilation, elle, cède : c'est un détail du chiffre, pas le chiffre.
  factory TillSummaryModel.fromJson(Map<String, dynamic> json) {
    return TillSummaryModel(
      total: (json['total'] as num).toInt(),
      fees: (json['fees'] as num).toInt(),
      boutique: (json['boutique'] as num).toInt(),
      byFeeCode: [
        for (final raw in (json['byFeeCode'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>) TillFeeCodeAmountModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'total': total,
    'fees': fees,
    'boutique': boutique,
    'byFeeCode': byFeeCode.map((line) => line.toJson()).toList(growable: false),
  };

  TillSummary toEntity() => TillSummary(
    total: total,
    fees: fees,
    boutique: boutique,
    byFeeCode: byFeeCode.map((line) => line.toEntity()).toList(growable: false),
  );
}
