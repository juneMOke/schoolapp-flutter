import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
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

  /// Le total **par devise** — jamais une somme unique.
  ///
  /// Les lignes non résolues comptent pour zéro, comme dans [totalInCents].
  MoneyBag get totals => MoneyBag.sumBy(
    lines,
    (line) => Money.parse(line.lineTotalInCents ?? 0, line.article.currency),
  );

  /// La devise du panier quand il n'en a qu'une, `null` s'il est vide **ou**
  /// s'il en mêle plusieurs.
  ///
  /// C'était « celle de sa première ligne » — une approximation qui laissait
  /// sceller une vente sous une unité choisie au hasard de l'ordre d'ajout.
  /// `null` en cas de mélange n'est pas un appauvrissement : c'est ce qui rend
  /// l'ambiguïté impossible à ignorer en aval.
  String? get currency => totals.soleEntry?.currency;

  /// Les devises distinctes présentes.
  Set<String> get currencies => {
    for (final line in lines) line.article.currency,
  };

  /// Vrai si le panier mélange deux devises.
  ///
  /// ## Détecté depuis l'origine, bloqué le temps que le contrat arrive
  ///
  /// La décision produit du 2026-08-29 laissait encaisser un panier mixte, le
  /// temps qu'une branche dédiée porte des totaux ventilés. C'est cette
  /// branche-ci, et le prédicat gardé à son intention sert enfin — mais pas
  /// pour interdire : pour **attendre**.
  ///
  /// La révision 4 du contrat autorise la vente mixte et en fait un seul acte
  /// de caisse (`sale.amounts[]`, `currency` par ligne). Tant qu'elle n'est pas
  /// fusionnée, la vente ne part qu'avec un total scalaire : le serveur
  /// scellerait un ticket additionnant deux unités, sans rien signaler au
  /// caissier — et un ticket scellé ne se corrige pas.
  ///
  /// ⇒ Blocage temporaire, levé par le lot « caisse multi-devise ».
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

    // Le mélange de devises vient EN DERNIER : les manques d'identité se
    // corrigent en tapant, celui-ci demande de défaire le panier. On ne met pas
    // en tête ce qui coûte le plus cher à réparer.
    if (isMultiCurrency) {
      blockers.add(const CartBlocker(CartBlockerKind.mixedCurrency));
    }

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
