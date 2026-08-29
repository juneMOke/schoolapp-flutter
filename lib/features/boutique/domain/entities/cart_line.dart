import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/boutique_price_resolver.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';

/// L'élève à qui la ligne est destinée.
///
/// Porte son **niveau**, parce que c'est lui qui résout le prix : l'opérateur
/// nomme l'enfant, il ne choisit pas le niveau. Nommer l'enfant *fait gagner* du
/// temps au guichet, il n'en coûte pas.
class CartBeneficiary extends Equatable {
  final String studentId;
  final String fullName;

  /// Niveau lu sur l'inscription de l'élève pour l'année courante.
  final String? schoolLevelId;

  /// Classe affichée sur la puce (« 6e A »), jamais utilisée pour le prix.
  final String? classroomLabel;

  /// Vrai si le serveur connaît déjà cet élève.
  ///
  /// Un élève inscrit hors ligne porte un uuid **client** que le serveur n'a pas
  /// honoré : le désigner ferait descendre une vente dont le bénéficiaire est un
  /// fantôme, avec une anomalie côté serveur et un reçu au bénéficiaire anonyme.
  final bool knownToServer;

  const CartBeneficiary({
    required this.studentId,
    required this.fullName,
    this.schoolLevelId,
    this.classroomLabel,
    this.knownToServer = true,
  });

  @override
  List<Object?> get props => [
    studentId,
    fullName,
    schoolLevelId,
    classroomLabel,
    knownToServer,
  ];
}

/// Une ligne du panier : un article, sa quantité, et pour qui.
///
/// **Bénéficiaire et niveau sont mutuellement exclusifs** : l'élève emporte son
/// niveau. Poser un bénéficiaire efface le niveau déclaré ; le retirer laisse la
/// ligne réclamer un niveau si l'article a une grille.
class CartLine extends Equatable {
  /// Identité locale de la ligne — un même article peut figurer plusieurs fois,
  /// pour trois enfants de niveaux différents.
  final String key;

  final BoutiqueArticle article;
  final CartBeneficiary? beneficiary;

  /// Niveau choisi au guichet (walk-in). Toujours `null` quand [beneficiary]
  /// est posé.
  final String? declaredLevelId;

  /// Attribut de remise, **sans effet sur le prix** (invariant I-3). Elle vit à
  /// côté de la quantité, jamais dans le bloc prix.
  final String? size;

  final int quantity;

  const CartLine({
    required this.key,
    required this.article,
    this.beneficiary,
    this.declaredLevelId,
    this.size,
    this.quantity = 1,
  });

  /// Le niveau qui résout le prix — une seule fonction, aucun autre chemin.
  String? get effectiveLevelId => BoutiquePriceResolver.effectiveLevelIdOf(
    beneficiaryLevelId: beneficiary?.schoolLevelId,
    declaredLevelId: declaredLevelId,
  );

  /// Prix unitaire en cents, ou `null` si la ligne n'est pas résolue.
  ///
  /// `null`, **jamais 0** : une ligne à zéro s'additionnerait en silence et se
  /// vendrait gratuitement.
  int? get unitPriceInCents =>
      BoutiquePriceResolver.resolve(article, levelId: effectiveLevelId);

  /// Total de la ligne, ou `null` si le prix ne l'est pas.
  ///
  /// Le serveur vérifie que ce total est bien le produit et rend
  /// `INCONSISTENT_TOTAL` sinon — sur une vente déjà encaissée.
  int? get lineTotalInCents {
    final unit = unitPriceInCents;
    return unit == null ? null : unit * quantity;
  }

  bool get isResolved => unitPriceInCents != null;

  /// Vrai si la ligne doit encore réclamer un niveau.
  bool get needsLevel =>
      BoutiquePriceResolver.needsLevel(article, levelId: effectiveLevelId);

  /// Vrai si la ligne peut absorber un ajout du même article.
  ///
  /// Une ligne « nue » — sans bénéficiaire, sans niveau, sans taille — est la
  /// seule à pouvoir s'incrémenter : toute autre porte une intention que le
  /// second exemplaire ne partage pas forcément.
  bool get isBare =>
      beneficiary == null && declaredLevelId == null && size == null;

  CartLine copyWith({
    CartBeneficiary? beneficiary,
    bool clearBeneficiary = false,
    String? declaredLevelId,
    bool clearDeclaredLevel = false,
    String? size,
    bool clearSize = false,
    int? quantity,
  }) => CartLine(
    key: key,
    article: article,
    beneficiary: clearBeneficiary ? null : (beneficiary ?? this.beneficiary),
    declaredLevelId: clearDeclaredLevel
        ? null
        : (declaredLevelId ?? this.declaredLevelId),
    size: clearSize ? null : (size ?? this.size),
    quantity: quantity ?? this.quantity,
  );

  @override
  List<Object?> get props => [
    key,
    article,
    beneficiary,
    declaredLevelId,
    size,
    quantity,
  ];
}
