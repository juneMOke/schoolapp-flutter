import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/beneficiary_article_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_amounts_json.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiary.dart';

/// Miroir d'une entrée de `items[]` — un élève bénéficiaire.
class BoutiqueBeneficiaryModel {
  final String studentId;
  final String fullName;

  /// `null` : élève inscrit mais pas encore placé en classe.
  final String? classId;
  final String? classLabel;
  final String lastPurchaseAt;
  final MoneyBag amounts;
  final List<BeneficiaryArticleModel> articles;

  const BoutiqueBeneficiaryModel({
    required this.studentId,
    required this.fullName,
    required this.lastPurchaseAt,
    required this.amounts,
    this.classId,
    this.classLabel,
    this.articles = const [],
  });

  factory BoutiqueBeneficiaryModel.fromJson(Map<String, dynamic> json) {
    final lastPurchaseAt = json['lastPurchaseAt'] as String;
    if (DateTime.tryParse(lastPurchaseAt) == null) {
      throw FormatException('Dernier achat illisible : $lastPurchaseAt');
    }
    return BoutiqueBeneficiaryModel(
      studentId: json['studentId'] as String,
      fullName: (json['fullName'] as String?) ?? '',
      classId: json['classId'] as String?,
      classLabel: json['classLabel'] as String?,
      lastPurchaseAt: lastPurchaseAt,
      amounts: BoutiqueAmountsJson.fromJson(json['amounts']),
      articles: [
        for (final raw in (json['articles'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>)
            BeneficiaryArticleModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'fullName': fullName,
    'classId': classId,
    'classLabel': classLabel,
    'lastPurchaseAt': lastPurchaseAt,
    'amounts': BoutiqueAmountsJson.toJson(amounts),
    'articles': [for (final article in articles) article.toJson()],
  };

  BoutiqueBeneficiary toEntity() => BoutiqueBeneficiary(
    studentId: studentId,
    fullName: fullName,
    // Un libellé vide n'est pas une classe : l'élève se lit « Sans classe ».
    classId: classId,
    classLabel: (classLabel?.trim().isEmpty ?? true) ? null : classLabel,
    lastPurchaseAt: DateTime.parse(lastPurchaseAt).toUtc(),
    amounts: amounts,
    articles: [for (final article in articles) article.toEntity()],
  );
}
