import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_summary.dart';

/// Miroir de `TillSummaryDto` — le chiffre de l'écran, en devise **reçue**.
class TillSummaryModel {
  final int total;
  final int fees;
  final int boutique;

  const TillSummaryModel({
    required this.total,
    required this.fees,
    required this.boutique,
  });

  /// **Aucune tolérance sur les trois montants.** Un résumé absent lève, et
  /// l'écran passe à l'erreur : un repli à zéro dirait « rien n'est entré
  /// aujourd'hui » à un caissier qui a le tiroir ouvert devant lui.
  factory TillSummaryModel.fromJson(Map<String, dynamic> json) {
    return TillSummaryModel(
      total: (json['total'] as num).toInt(),
      fees: (json['fees'] as num).toInt(),
      boutique: (json['boutique'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'total': total,
    'fees': fees,
    'boutique': boutique,
  };

  TillSummary toEntity() =>
      TillSummary(total: total, fees: fees, boutique: boutique);
}
