import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';

/// Un article vendable du catalogue de l'école, tel que la caisse le connaît
/// **hors ligne**.
///
/// Descend dans la section `boutiqueArticles` du bundle référentiel, remplacée
/// en bloc : il n'y a ni curseur ni version à porter. Les articles retirés de la
/// vente ne descendent pas — le poste reçoit ce qu'il peut vendre.
class BoutiqueArticle extends Equatable {
  final String id;
  final String academicYearId;

  /// Ce que l'opérateur lit et saisit. Unique par (école, année).
  final String code;

  final String label;

  /// `null` quand le serveur sert une famille que ce client ne connaît pas
  /// encore. L'article reste **vendable** — son prix ne dépend pas de sa
  /// famille — mais il se range à part plutôt que sous une famille inventée.
  final ArticleFamily? family;

  /// **Déclaré, jamais inféré** (invariant I-1). `null` sur un mode illisible :
  /// l'article est alors invendable, ce qui est le seul repli sûr — le prendre
  /// pour un prix unique le vendrait sans demander le niveau.
  final PricingMode? pricingMode;

  /// Renseigné **si et seulement si** [PricingMode.prixUnique].
  final int? unitPriceInCents;

  /// La grille, `{schoolLevelId: montant}`. Renseignée **si et seulement si**
  /// [PricingMode.prixParNiveau].
  final Map<String, int> levelPrices;

  final String currency;

  const BoutiqueArticle({
    required this.id,
    required this.academicYearId,
    required this.code,
    required this.label,
    required this.family,
    required this.pricingMode,
    this.unitPriceInCents,
    this.levelPrices = const {},
    required this.currency,
  });

  /// Vrai si la vente doit désigner un niveau — par un bénéficiaire, dont le
  /// niveau se déduit, ou par un niveau choisi au guichet.
  ///
  /// Lu sur [pricingMode] et **jamais** sur la forme des prix : c'est
  /// littéralement l'invariant I-1.
  bool get requiresLevel => pricingMode == PricingMode.prixParNiveau;

  /// Vrai si le badge « par niveau » doit s'afficher.
  ///
  /// Identique à [requiresLevel], et nommé à part pour que l'écran n'ait aucune
  /// raison d'écrire sa propre condition : un article à grille dont toutes les
  /// cases valent 10 $ porte le badge, un article plat à 10 $ ne le porte
  /// jamais. Ne **jamais** comparer [minPriceInCents] et [maxPriceInCents] pour
  /// en décider — seulement pour composer la fourchette affichée.
  bool get showsLevelBadge => requiresLevel;

  /// Vrai si l'article ne peut pas être vendu par cette version du client.
  ///
  /// Un seul cas : un mode de tarification illisible. La famille inconnue, elle,
  /// n'empêche rien.
  bool get isSellable => pricingMode != null;

  /// Le plus petit montant de la grille, ou le prix unique. `null` si l'article
  /// n'a aucun prix — un article à grille vide, que le catalogue ne devrait pas
  /// servir.
  int? get minPriceInCents => _bound((a, b) => a < b);

  /// Le plus grand montant de la grille, ou le prix unique.
  int? get maxPriceInCents => _bound((a, b) => a > b);

  int? _bound(bool Function(int, int) keeps) {
    if (pricingMode == PricingMode.prixUnique) return unitPriceInCents;
    if (levelPrices.isEmpty) return null;
    return levelPrices.values.reduce((a, b) => keeps(a, b) ? a : b);
  }

  @override
  List<Object?> get props => [
    id,
    academicYearId,
    code,
    label,
    family,
    pricingMode,
    unitPriceInCents,
    levelPrices,
    currency,
  ];
}
