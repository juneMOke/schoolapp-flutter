import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_blocker.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';

/// Le panier d'une vente — **domaine pur**, aucun widget, aucune chaîne d'UI.
///
/// Immuable : chaque geste rend un nouveau panier. C'est ce qui rend l'ensemble
/// exerçable sans monter d'écran, et c'est là que vivent les règles qui portent
/// de l'argent.
class BoutiqueCart extends Equatable {
  final List<CartLine> lines;
  final CartPayer payer;

  const BoutiqueCart({this.lines = const [], this.payer = const CartPayer()});

  bool get isEmpty => lines.isEmpty;

  /// Somme des **quantités**, pas le nombre de lignes : « 3 articles » quand une
  /// seule ligne porte trois exemplaires.
  int get articleCount => lines.fold(0, (sum, line) => sum + line.quantity);

  /// Total à encaisser, en cents.
  ///
  /// Les lignes non résolues comptent pour **zéro dans l'affichage** — mais
  /// elles bloquent l'action, ce que [blockers] dit. Sans ce blocage, le total
  /// affiché serait celui d'un panier incomplet et le guichet encaisserait
  /// moins que ce qu'il remet.
  int get totalInCents =>
      lines.fold(0, (sum, line) => sum + (line.lineTotalInCents ?? 0));

  /// La devise du panier : celle de sa première ligne, `null` s'il est vide.
  ///
  /// ⚠️ **Approximation assumée sur un panier multi-devises** — voir
  /// [isMultiCurrency].
  String? get currency => lines.isEmpty ? null : lines.first.article.currency;

  /// Les devises distinctes présentes.
  Set<String> get currencies => {
    for (final line in lines) line.article.currency,
  };

  /// Vrai si le panier mélange deux devises.
  ///
  /// ## ⚠️ Détecté, PAS bloqué — décision produit du 2026-08-29
  ///
  /// Le mélange **n'empêche pas d'encaisser**, sur arbitrage explicite : la
  /// gestion des deux devises est renvoyée à une branche dédiée, où le panier
  /// portera des totaux ventilés plutôt qu'une somme unique.
  ///
  /// **Ce que cela laisse ouvert, en attendant.** Le serveur ne refuse plus ce
  /// cas non plus — il écarte la référence de prix et consigne une anomalie. Un
  /// panier USD + CDF est donc additionné par [totalInCents], encaissé, et
  /// scellé avec un total qui n'a pas de sens, sans que rien ne le signale au
  /// caissier. C'est le trou que la branche multi-devises devra fermer.
  ///
  /// Le prédicat est **gardé** plutôt que retiré : il est ce sur quoi cette
  /// branche s'appuiera, et le supprimer obligerait à le réinventer.
  bool get isMultiCurrency => currencies.length > 1;

  /// Somme des quantités des lignes portant cet article — la pastille de la
  /// carte.
  int quantityOfArticle(String articleId) => lines
      .where((line) => line.article.id == articleId)
      .fold(0, (sum, line) => sum + line.quantity);

  /// Ce qui empêche d'encaisser, **dans l'ordre où l'utilisateur peut le
  /// corriger** (spec §10).
  ///
  /// Vide = prêt. L'ordre est une règle métier, pas une préférence
  /// d'affichage : il descend du haut du formulaire vers le panier, comme le
  /// regard.
  List<CartBlocker> get blockers {
    // Panier vide : SEUL. Reprocher au guichet de n'avoir pas nommé le payeur
    // d'une vente qui n'existe pas encore ferait trois reproches pour un seul
    // geste à faire.
    if (isEmpty) return const [CartBlocker(CartBlockerKind.emptyCart)];

    final blockers = <CartBlocker>[
      if (payer.lastName.trim().isEmpty)
        const CartBlocker(CartBlockerKind.missingLastName),
      if (payer.middleName.trim().isEmpty)
        const CartBlocker(CartBlockerKind.missingMiddleName),
      if (payer.firstName.trim().isEmpty)
        const CartBlocker(CartBlockerKind.missingFirstName),
      if (payer.phoneStatus == PayerPhoneStatus.missing)
        const CartBlocker(CartBlockerKind.missingPhone),
      if (payer.phoneStatus == PayerPhoneStatus.incomplete)
        const CartBlocker(CartBlockerKind.incompletePhone),
    ];

    final unresolved = lines.where((line) => !line.isResolved).length;
    if (unresolved > 0) {
      blockers.add(
        CartBlocker(CartBlockerKind.linesWithoutLevel, count: unresolved),
      );
    }

    // ⚠️ Le mélange de devises ne figure PAS ici : il est détecté
    // ([isMultiCurrency]) mais n'empêche pas d'encaisser, par décision produit
    // — la gestion des deux devises est traitée sur une branche dédiée.
    return blockers;
  }

  bool get canCollect => blockers.isEmpty;

  /// Ajoute un article.
  ///
  /// **Incrémente** la première ligne « nue » du même article — sans
  /// bénéficiaire, sans niveau, sans taille. Sinon **empile** une nouvelle
  /// ligne : une ligne déjà destinée à un enfant porte une intention que le
  /// second exemplaire ne partage pas forcément.
  ///
  /// [keyOf] fabrique l'identité de la ligne neuve — injectée pour que le test
  /// n'ait pas à deviner un uuid.
  BoutiqueCart addArticle(
    BoutiqueArticle article, {
    required String Function() keyOf,
  }) {
    final index = lines.indexWhere(
      (line) => line.article.id == article.id && line.isBare,
    );
    if (index >= 0) {
      final line = lines[index];
      return _withLines([
        ...lines.sublist(0, index),
        line.copyWith(quantity: line.quantity + 1),
        ...lines.sublist(index + 1),
      ]);
    }
    return _withLines([...lines, CartLine(key: keyOf(), article: article)]);
  }

  /// Y a-t-il, pour cet article, un exemplaire encore libre de toute intention ?
  ///
  /// C'est ce que le pas de la vignette peut défaire — et lui seul.
  bool hasBareLineOfArticle(String articleId) =>
      lines.any((line) => line.article.id == articleId && line.isBare);

  /// Retire un exemplaire **non encore destiné à un enfant**, depuis le
  /// catalogue.
  ///
  /// Le pas de la vignette n'agit que sur la ligne « nue », miroir exact
  /// d'[addArticle]. Une ligne déjà désignée à un bénéficiaire porte une
  /// intention que le catalogue ne connaît pas : la défaire depuis une vignette
  /// la ferait disparaître sans que le guichet voie de quel enfant il
  /// s'agissait. Elle se retire au panier, où le nom est sous les yeux.
  ///
  /// **Le dernier exemplaire emporte la ligne** — contrairement au compteur du
  /// panier, qui plancherait à 1. Sans cela la vignette resterait bloquée sur
  /// « 1 », sans aucun moyen de revenir au bouton d'ajout.
  BoutiqueCart removeOneBareArticle(String articleId) {
    final index = lines.indexWhere(
      (line) => line.article.id == articleId && line.isBare,
    );
    if (index < 0) return this;
    final line = lines[index];
    if (line.quantity <= 1) return removeLine(line.key);
    return _withLines([
      ...lines.sublist(0, index),
      line.copyWith(quantity: line.quantity - 1),
      ...lines.sublist(index + 1),
    ]);
  }

  /// Retire une ligne — **immédiat, sans confirmation** : le panier n'est pas
  /// encore un engagement, et l'ajout se refait d'un geste.
  BoutiqueCart removeLine(String key) => _withLines([
    for (final line in lines)
      if (line.key != key) line,
  ]);

  /// Change la quantité. Descendre sous 1 est **impossible** : le retrait se
  /// fait par la corbeille, jamais par le pas du compteur — un compteur qui
  /// supprime surprend, et l'action est irréversible sans re-toucher l'article.
  BoutiqueCart setQuantity(String key, int quantity) => _mapLine(
    key,
    (line) => line.copyWith(quantity: quantity < 1 ? 1 : quantity),
  );

  /// Désigne le bénéficiaire d'une ligne — et **efface le niveau déclaré** :
  /// l'élève emporte son niveau.
  BoutiqueCart setBeneficiary(String key, CartBeneficiary beneficiary) =>
      _mapLine(
        key,
        (line) =>
            line.copyWith(beneficiary: beneficiary, clearDeclaredLevel: true),
      );

  /// Retire le bénéficiaire. La ligne réclamera de nouveau un niveau si
  /// l'article a une grille.
  BoutiqueCart clearBeneficiary(String key) =>
      _mapLine(key, (line) => line.copyWith(clearBeneficiary: true));

  /// Pose le niveau d'une ligne walk-in.
  ///
  /// **Sans effet quand un bénéficiaire est posé** : l'exclusion est tenue ici
  /// et non par l'écran, pour qu'aucun chemin — restauration d'un panier,
  /// rejeu — ne puisse produire une ligne portant les deux.
  BoutiqueCart setDeclaredLevel(String key, String? levelId) => _mapLine(
    key,
    (line) => line.beneficiary != null
        ? line
        : line.copyWith(
            declaredLevelId: levelId,
            clearDeclaredLevel: levelId == null,
          ),
  );

  BoutiqueCart setSize(String key, String? size) => _mapLine(
    key,
    (line) => line.copyWith(size: size, clearSize: size == null),
  );

  BoutiqueCart withPayer(CartPayer payer) =>
      BoutiqueCart(lines: lines, payer: payer);

  /// Vide tout — lignes **et** payeur. C'est « Vider le panier » du pied, et
  /// c'est aussi ce que fait « Nouvelle vente » après un encaissement.
  BoutiqueCart cleared() => const BoutiqueCart();

  BoutiqueCart _withLines(List<CartLine> lines) =>
      BoutiqueCart(lines: lines, payer: payer);

  BoutiqueCart _mapLine(String key, CartLine Function(CartLine) transform) =>
      _withLines([
        for (final line in lines)
          if (line.key == key) transform(line) else line,
      ]);

  @override
  List<Object?> get props => [lines, payer];
}
