import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_blocker.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_tender.dart';

/// Le panier d'une vente — **domaine pur**, aucun widget, aucune chaîne d'UI.
///
/// Immuable : chaque geste rend un nouveau panier. C'est ce qui rend l'ensemble
/// exerçable sans monter d'écran, et c'est là que vivent les règles qui portent
/// de l'argent.
class BoutiqueCart extends Equatable {
  final List<CartLine> lines;
  final CartPayer payer;

  /// Comment le client règle, **par devise de catalogue**. Vide = tout dans la
  /// devise où c'est tarifé, c'est-à-dire l'écran d'avant.
  final Map<String, CartTender> tenders;

  const BoutiqueCart({
    this.lines = const [],
    this.payer = const CartPayer(),
    this.tenders = const {},
  });

  /// Le règlement retenu pour cette devise de catalogue.
  CartTender tenderFor(String catalogCurrency) =>
      tenders[CurrencyCode.normalize(catalogCurrency)] ?? const CartTender();

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

  /// Les devises distinctes présentes, **normalisées**.
  ///
  /// Normalisées parce que tout le reste l'est : `totals` passe par
  /// `Money.parse`, et les clés de [tenders] viennent de là. Comparer un code
  /// brut du catalogue (« usd ») à une clé normalisée ferait disparaître le
  /// règlement choisi au premier changement de quantité — sans un mot.
  Set<String> get currencies => {
    for (final line in lines) CurrencyCode.normalize(line.article.currency),
  };

  /// Vrai si le panier mélange deux devises.
  ///
  /// ## Détecté, et désormais parfaitement licite
  ///
  /// Le prédicat a servi trois fois : à bloquer, puis à laisser passer (décision
  /// produit du 2026-08-29), puis à bloquer de nouveau le temps que le contrat
  /// porte `amounts[]`. Il ne bloque plus rien — mais il reste **la** façon de
  /// savoir si le panier mêle deux unités, ce dont l'affichage a besoin.
  ///
  /// `totalInCents` n'est plus la vérité du panier : [totals] l'est.
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
    // Panier vide : SEUL. Reprocher au guichet un numéro inachevé sur une vente
    // qui n'existe pas encore ferait deux reproches pour un seul geste à faire.
    if (isEmpty) return const [CartBlocker(CartBlockerKind.emptyCart)];

    // ⚠️ **L'identité du payeur ne bloque plus RIEN** (V114 serveur / v43
    // locale). Ni nom, ni post-nom, ni prénom, ni même le fait d'avoir un
    // numéro. Une vente au comptant remet sa contrepartie sur-le-champ : pas de
    // dette à rattacher, pas de relance, personne à recontacter pour solder
    // quoi que ce soit. L'exigence, elle, se payait comptant au guichet — la
    // file attend pendant qu'on demande son état civil à quelqu'un qui achète
    // un cahier, et le guichetier finit par taper « X ». Un payeur ABSENT vaut
    // mieux qu'un payeur INVENTÉ.
    //
    // Seul survit le numéro À MOITIÉ TAPÉ : ce n'est pas une absence mais une
    // faute de frappe, et c'est la clé de rapprochement du répertoire.
    final blockers = <CartBlocker>[
      if (payer.phoneStatus == PayerPhoneStatus.incomplete)
        const CartBlocker(CartBlockerKind.incompletePhone),
    ];

    final unresolved = lines.where((line) => !line.isResolved).length;
    if (unresolved > 0) {
      blockers.add(
        CartBlocker(CartBlockerKind.linesWithoutLevel, count: unresolved),
      );
    }

    // ⚠️ Le mélange de devises ne figure PAS ici, et cette fois pour de bon :
    // le contrat porte `sale.amounts[]` et une `currency` par ligne. Un panier
    // qui règle 450,00 $ d'uniformes et 90 000 FC de manuels est un acte de
    // caisse — une vente, un reçu. Imposer deux gestes au caissier serait
    // laisser le schéma dicter le métier.
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
      BoutiqueCart(lines: lines, payer: payer, tenders: tenders);

  /// Pose la devise dans laquelle cette part du panier est réglée.
  ///
  /// Choisir la devise du catalogue **efface** l'entrée plutôt que d'en garder
  /// une neutre : le montant tendu qui l'accompagnait n'a plus d'objet, et le
  /// laisser derrière ferait ressortir un chiffre saisi pour une autre unité.
  BoutiqueCart withTenderCurrency(String catalogCurrency, String currency) {
    final pivot = CurrencyCode.normalize(catalogCurrency);
    final target = CurrencyCode.normalize(currency);
    final next = Map<String, CartTender>.from(tenders);
    if (target.isEmpty || target == pivot) {
      next.remove(pivot);
    } else {
      next[pivot] = CartTender(currency: target);
    }
    return BoutiqueCart(lines: lines, payer: payer, tenders: next);
  }

  /// Pose ce que le client a **tendu** pour cette part du panier.
  ///
  /// Sans devise de règlement choisie, il n'y a rien à porter : le montant dû
  /// est le montant tendu, et un champ de plus ne dirait rien.
  BoutiqueCart withTenderedAmount(String catalogCurrency, int? cents) {
    final pivot = CurrencyCode.normalize(catalogCurrency);
    final current = tenders[pivot];
    if (current == null) return this;
    final next = Map<String, CartTender>.from(tenders);
    next[pivot] = cents == null
        ? current.copyWith(clearTendered: true)
        : current.copyWith(tenderedCents: cents);
    return BoutiqueCart(lines: lines, payer: payer, tenders: next);
  }

  /// Vide tout — lignes **et** payeur. C'est « Vider le panier » du pied, et
  /// c'est aussi ce que fait « Nouvelle vente » après un encaissement.
  BoutiqueCart cleared() => const BoutiqueCart();

  /// ⚠️ **Les règlements des devises disparues sont retirés.** Vider la
  /// dernière ligne en dollars laisserait sinon un « le client règle en francs »
  /// orphelin, qui ressortirait au prochain article en dollars ajouté — avec un
  /// montant tendu saisi pour un panier qui n'existe plus.
  BoutiqueCart _withLines(List<CartLine> lines) {
    final next = BoutiqueCart(lines: lines, payer: payer, tenders: tenders);
    final present = next.currencies;
    return BoutiqueCart(
      lines: lines,
      payer: payer,
      tenders: {
        for (final entry in tenders.entries)
          if (present.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  BoutiqueCart _mapLine(String key, CartLine Function(CartLine) transform) =>
      _withLines([
        for (final line in lines)
          if (line.key == key) transform(line) else line,
      ]);

  @override
  List<Object?> get props => [lines, payer, tenders];
}
