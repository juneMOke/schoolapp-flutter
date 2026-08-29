part of 'boutique_bloc.dart';

/// Où en est le chargement du catalogue.
enum BoutiqueStatus {
  /// Rien n'a encore été demandé.
  initial,

  /// Catalogue en cours de lecture — squelettes à l'écran, dans la MÊME grille
  /// que les cartes réelles.
  loading,

  /// Catalogue en main. Peut être vide, et le vide a deux causes distinctes —
  /// voir [BoutiqueCatalog.withheld].
  ready,

  /// Lecture impossible. L'écran ENTIER passe en erreur : il n'y a rien à
  /// vendre sans catalogue.
  failure,
}

/// L'écran de caisse.
///
/// **Le panier ne dépend ni de la recherche ni du filtre**, et il survit à un
/// rechargement du catalogue : une vente en composition ne se perd pas parce
/// qu'un pull est passé.
class BoutiqueState extends Equatable {
  final BoutiqueStatus status;

  /// Le catalogue, avec la raison de son vide s'il est vide.
  final BoutiqueCatalog catalog;

  /// Le panier en composition.
  final BoutiqueCart cart;

  /// Recherche libre — porte sur le libellé ET le code, sans seuil ni debounce
  /// (les données sont locales).
  final String query;

  /// Famille sélectionnée, `null` = « Toutes ».
  final ArticleFamily? familyFilter;

  /// Échec de lecture, pour que l'écran d'erreur dise lequel des quatre cas il
  /// affiche.
  final Failure? failure;

  /// Le payeur reconnu au répertoire pour le numéro courant, `null` sinon.
  ///
  /// `null` couvre trois cas que l'écran distingue par le seul état du
  /// téléphone : trop court pour être jugé, inconnu, ou répertoire illisible.
  /// Les trois se rendent pareil — on ne propose rien — et c'est voulu : une
  /// suggestion de confort ne doit jamais produire un message d'erreur au
  /// milieu d'une vente.
  final BoutiquePayer? payerMatch;

  /// Vrai pendant l'écriture de la vente — verrou anti-double-envoi.
  final bool isCollecting;

  /// La vente qui vient d'être encaissée, `null` tant qu'il n'y en a pas.
  ///
  /// Sa présence est ce qui fait passer l'écran du panier au reçu, et ce qui
  /// interdit un second encaissement du même panier.
  final RecordedSale? recordedSale;

  /// Échec de l'écriture locale. Distinct de [failure], qui porte l'erreur de
  /// LECTURE du catalogue : celle-ci s'affiche **dans la modale**, sans jamais
  /// remplacer l'écran — la vente est déjà composée.
  final Failure? saleFailure;

  const BoutiqueState({
    this.status = BoutiqueStatus.initial,
    this.catalog = const BoutiqueCatalog(articles: [], withheld: false),
    this.cart = const BoutiqueCart(),
    this.query = '',
    this.familyFilter,
    this.failure,
    this.payerMatch,
    this.isCollecting = false,
    this.recordedSale,
    this.saleFailure,
  });

  /// Le catalogue filtré, groupé par famille, dans l'ordre de l'énumération.
  ///
  /// Les groupes vides sont **absents** : une famille qu'un filtre ou une
  /// recherche a vidée ne laisse aucun intitulé orphelin.
  Map<ArticleFamily, List<BoutiqueArticle>> get visibleByFamily {
    final normalized = query.trim().toLowerCase();
    final grouped = <ArticleFamily, List<BoutiqueArticle>>{};
    for (final entry in catalog.byFamily.entries) {
      if (familyFilter != null && entry.key != familyFilter) continue;
      final matching = [
        for (final article in entry.value)
          if (normalized.isEmpty ||
              article.label.toLowerCase().contains(normalized) ||
              article.code.toLowerCase().contains(normalized))
            article,
      ];
      if (matching.isNotEmpty) grouped[entry.key] = matching;
    }
    return grouped;
  }

  /// Vrai si le catalogue a des articles mais qu'aucun ne passe les critères.
  ///
  /// Distinct du catalogue vide : le message cite alors la requête et le filtre,
  /// et propose de les réinitialiser — là où un catalogue vide renvoie à sa
  /// gestion.
  bool get hasNoMatch => !catalog.isEmpty && visibleByFamily.isEmpty;

  bool get hasActiveFilters => query.trim().isNotEmpty || familyFilter != null;

  BoutiqueState copyWith({
    BoutiqueStatus? status,
    BoutiqueCatalog? catalog,
    BoutiqueCart? cart,
    String? query,
    ArticleFamily? familyFilter,
    bool clearFamilyFilter = false,
    Failure? failure,
    bool clearFailure = false,
    BoutiquePayer? payerMatch,
    bool clearPayerMatch = false,
    bool? isCollecting,
    RecordedSale? recordedSale,
    bool clearRecordedSale = false,
    Failure? saleFailure,
    bool clearSaleFailure = false,
  }) => BoutiqueState(
    status: status ?? this.status,
    catalog: catalog ?? this.catalog,
    cart: cart ?? this.cart,
    query: query ?? this.query,
    familyFilter: clearFamilyFilter
        ? null
        : (familyFilter ?? this.familyFilter),
    failure: clearFailure ? null : (failure ?? this.failure),
    payerMatch: clearPayerMatch ? null : (payerMatch ?? this.payerMatch),
    isCollecting: isCollecting ?? this.isCollecting,
    recordedSale: clearRecordedSale
        ? null
        : (recordedSale ?? this.recordedSale),
    saleFailure: clearSaleFailure ? null : (saleFailure ?? this.saleFailure),
  );

  @override
  List<Object?> get props => [
    status,
    catalog,
    cart,
    query,
    familyFilter,
    failure,
    payerMatch,
    isCollecting,
    recordedSale,
    saleFailure,
  ];
}
