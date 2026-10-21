import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_amounts_json.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_top_article.dart';

/// Miroir d'une entrée de `topArticles[]`.
class BoutiqueTopArticleModel {
  final String articleId;
  final String label;
  final String family;
  final int quantity;
  final MoneyBag amounts;

  const BoutiqueTopArticleModel({
    required this.articleId,
    required this.label,
    required this.family,
    required this.quantity,
    required this.amounts,
  });

  factory BoutiqueTopArticleModel.fromJson(Map<String, dynamic> json) =>
      BoutiqueTopArticleModel(
        articleId: json['articleId'] as String,
        label: (json['label'] as String?) ?? '',
        family: (json['family'] as String?) ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        amounts: BoutiqueAmountsJson.fromJson(json['amounts']),
      );

  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'label': label,
    'family': family,
    'quantity': quantity,
    'amounts': BoutiqueAmountsJson.toJson(amounts),
  };

  BoutiqueTopArticle toEntity() => BoutiqueTopArticle(
    articleId: articleId,
    label: label,
    family: ArticleFamily.fromWire(family),
    quantity: quantity,
    amounts: amounts,
  );
}
