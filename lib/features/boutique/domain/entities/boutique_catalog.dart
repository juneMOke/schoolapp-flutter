import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';

/// Le catalogue tel que l'écran de caisse le reçoit — **avec la raison de son
/// vide**, quand il est vide.
///
/// Deux vides se ressemblent à l'écran et n'appellent pas le même geste :
///
///  - `withheld: true` — le serveur n'a pas servi la section, faute de
///    `boutique.catalog.read`. Il n'y a rien à créer : il manque un droit.
///  - `withheld: false` avec [articles] vide — l'école n'a pas encore d'article,
///    et le geste est d'en créer un.
///
/// Les confondre ferait conclure au guichet que l'école n'a rien paramétré alors
/// qu'il lui manque une permission — et personne n'irait chercher du côté des
/// droits.
class BoutiqueCatalog extends Equatable {
  final List<BoutiqueArticle> articles;

  /// Vrai si le catalogue n'a pas été **communiqué** à ce porteur de session.
  final bool withheld;

  const BoutiqueCatalog({required this.articles, required this.withheld});

  const BoutiqueCatalog.withheld() : articles = const [], withheld = true;

  bool get isEmpty => articles.isEmpty;

  /// Les articles **vendables**, groupés par famille, dans l'ordre de
  /// l'énumération — jamais l'alphabet, jamais le volume de ventes.
  ///
  /// Les familles sans article visible sont **absentes** de la map : un
  /// intitulé de groupe orphelin annoncerait une section vide sous un filtre
  /// qui l'a précisément vidée.
  Map<ArticleFamily, List<BoutiqueArticle>> get byFamily {
    final grouped = <ArticleFamily, List<BoutiqueArticle>>{};
    for (final family in ArticleFamily.values) {
      final ofFamily = [
        for (final article in articles)
          if (article.family == family && article.isSellable) article,
      ]..sort((a, b) => a.label.compareTo(b.label));
      if (ofFamily.isNotEmpty) grouped[family] = ofFamily;
    }
    return grouped;
  }

  /// Les articles que ce client ne sait pas vendre — mode de tarification
  /// inconnu, servi par un serveur plus récent.
  ///
  /// Ils ne sont pas jetés en silence : un catalogue amputé sans explication
  /// enverrait le guichet chercher un article que la direction jure avoir créé.
  List<BoutiqueArticle> get unsellable => [
    for (final article in articles)
      if (!article.isSellable) article,
  ];

  @override
  List<Object?> get props => [articles, withheld];
}
