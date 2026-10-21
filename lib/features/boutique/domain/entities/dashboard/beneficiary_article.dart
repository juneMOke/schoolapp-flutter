import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';

/// Un article reçu par un élève sur la fenêtre, cumulé sur ses achats.
class BeneficiaryArticle extends Equatable {
  final String articleId;
  final String label;
  final ArticleFamily? family;
  final int quantity;

  /// Les tailles servies (« M », « L »), vides pour un article sans taille.
  final List<String> sizes;

  const BeneficiaryArticle({
    required this.articleId,
    required this.label,
    required this.family,
    required this.quantity,
    this.sizes = const [],
  });

  @override
  List<Object?> get props => [articleId, label, family, quantity, sizes];
}
