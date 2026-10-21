import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_article.dart';

/// Miroir d'une entrée de `items[].articles[]`.
class BeneficiaryArticleModel {
  final String articleId;
  final String label;
  final String family;
  final int quantity;
  final List<String> sizes;

  const BeneficiaryArticleModel({
    required this.articleId,
    required this.label,
    required this.family,
    required this.quantity,
    this.sizes = const [],
  });

  factory BeneficiaryArticleModel.fromJson(Map<String, dynamic> json) =>
      BeneficiaryArticleModel(
        articleId: (json['articleId'] as String?) ?? '',
        label: (json['label'] as String?) ?? '',
        family: (json['family'] as String?) ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        sizes: [
          for (final size in (json['sizes'] as List<dynamic>? ?? const []))
            if (size is String && size.trim().isNotEmpty) size.trim(),
        ],
      );

  Map<String, dynamic> toJson() => {
    'articleId': articleId,
    'label': label,
    'family': family,
    'quantity': quantity,
    'sizes': sizes,
  };

  BeneficiaryArticle toEntity() => BeneficiaryArticle(
    articleId: articleId,
    label: label,
    family: ArticleFamily.fromWire(family),
    quantity: quantity,
    sizes: sizes,
  );
}
