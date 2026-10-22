import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';

/// Un des cinq articles les plus vendus **en quantité** sur la fenêtre.
///
/// Par quantité, pas par montant : un retrait de dossier à 15 $ ne doit pas
/// masquer vingt-deux journaux de classe.
class BoutiqueTopArticle extends Equatable {
  final String articleId;

  /// Recopié de la ligne : un article retiré du catalogue garde son nom.
  final String label;

  final ArticleFamily? family;
  final int quantity;

  /// Plusieurs devises si celle de l'article a changé dans la fenêtre — jamais
  /// additionnées.
  final MoneyBag amounts;

  const BoutiqueTopArticle({
    required this.articleId,
    required this.label,
    required this.family,
    required this.quantity,
    required this.amounts,
  });

  @override
  List<Object?> get props => [articleId, label, family, quantity, amounts];
}
