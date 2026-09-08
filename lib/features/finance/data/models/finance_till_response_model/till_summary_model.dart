import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_summary.dart';

/// Miroir de `TillSummaryDto` — le chiffre de l'écran, en devise **reçue**.
class TillSummaryModel {
  final int total;
  final int fees;
  final int boutique;
  final int receiptCount;
  final int averageTicket;
  final int? trendPercent;

  const TillSummaryModel({
    required this.total,
    required this.fees,
    required this.boutique,
    required this.receiptCount,
    required this.averageTicket,
    this.trendPercent,
  });

  /// **Aucune tolérance sur les trois montants.** Un résumé absent lève, et
  /// l'écran passe à l'erreur : un repli à zéro dirait « rien n'est entré
  /// aujourd'hui » à un caissier qui a le tiroir ouvert devant lui.
  ///
  /// Le compteur et le ticket moyen cèdent à zéro, eux : ce sont des lectures du
  /// montant, et un zéro y est indiscernable de l'absence — une caisse sans reçu
  /// a bien un compteur à zéro et pas de ticket moyen.
  ///
  /// **`trendPercent` ne cède pas, il se tait.** Absent du fil ⇒ `null` ⇒ carte
  /// masquée. Le replier sur zéro annoncerait « stable » là où le serveur a
  /// justement refusé de conclure, faute de période précédente à comparer : c'est
  /// la seule clé de ce modèle où `null` et `0` disent deux choses différentes.
  factory TillSummaryModel.fromJson(Map<String, dynamic> json) {
    return TillSummaryModel(
      total: (json['total'] as num).toInt(),
      fees: (json['fees'] as num).toInt(),
      boutique: (json['boutique'] as num).toInt(),
      receiptCount: (json['receiptCount'] as num?)?.toInt() ?? 0,
      averageTicket: (json['averageTicket'] as num?)?.toInt() ?? 0,
      trendPercent: (json['trendPercent'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'total': total,
    'fees': fees,
    'boutique': boutique,
    'receiptCount': receiptCount,
    'averageTicket': averageTicket,
    'trendPercent': trendPercent,
  };

  TillSummary toEntity() => TillSummary(
    total: total,
    fees: fees,
    boutique: boutique,
    receiptCount: receiptCount,
    averageTicket: averageTicket,
    trendPercent: trendPercent,
  );
}
