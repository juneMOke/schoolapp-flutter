import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_blocker.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';

BoutiqueArticle _polo({String currency = 'USD'}) => BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'ay-1',
  code: 'POLO',
  label: 'Polo Lacoste',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixParNiveau,
  levelPrices: const {'primaire': 1000, 'humanites': 1500},
  currency: currency,
);

BoutiqueArticle _ecusson({String currency = 'USD', String id = 'art-ecu'}) =>
    BoutiqueArticle(
      id: id,
      academicYearId: 'ay-1',
      code: 'ECUS',
      label: 'Écusson brodé',
      family: ArticleFamily.uniforme,
      pricingMode: PricingMode.prixUnique,
      unitPriceInCents: 1000,
      currency: currency,
    );

const _david = CartBeneficiary(
  studentId: 'elv-1',
  fullName: 'David Mwepu',
  schoolLevelId: 'humanites',
  classroomLabel: '1ère HUM',
);

/// Payeur complet — pour n'observer que le blocage qu'on teste.
const _payeurComplet = CartPayer(
  lastName: 'Ndombo',
  middleName: 'Lelo',
  firstName: 'Willy',
  phoneNumber: '+243810220145',
);

int _n = 0;
String _key() => 'k${_n++}';

void main() {
  setUp(() => _n = 0);

  group('ajouter un article', () {
    test('une ligne nue du même article s\'incrémente', () {
      var cart = const BoutiqueCart().addArticle(_ecusson(), keyOf: _key);
      cart = cart.addArticle(_ecusson(), keyOf: _key);

      expect(cart.lines, hasLength(1));
      expect(cart.lines.single.quantity, 2);
      expect(cart.articleCount, 2);
    });

    test('une ligne DÉJÀ destinée à un enfant ne s\'incrémente pas', () {
      // Elle porte une intention que le second exemplaire ne partage pas
      // forcément : l'incrémenter habillerait deux fois le même enfant sans
      // qu'on l'ait demandé.
      var cart = const BoutiqueCart().addArticle(_polo(), keyOf: _key);
      cart = cart.setBeneficiary(cart.lines.single.key, _david);

      cart = cart.addArticle(_polo(), keyOf: _key);

      expect(cart.lines, hasLength(2));
      expect(cart.lines.first.beneficiary, _david);
      expect(cart.lines.last.beneficiary, isNull);
    });

    test('une ligne portant une taille ne s\'incrémente pas non plus', () {
      var cart = const BoutiqueCart().addArticle(_polo(), keyOf: _key);
      cart = cart.setSize(cart.lines.single.key, 'M');

      cart = cart.addArticle(_polo(), keyOf: _key);

      expect(cart.lines, hasLength(2));
    });

    test('la pastille compte les quantités de TOUTES les lignes', () {
      var cart = const BoutiqueCart().addArticle(_polo(), keyOf: _key);
      cart = cart.setBeneficiary(cart.lines.single.key, _david);
      cart = cart.addArticle(_polo(), keyOf: _key);
      cart = cart.setQuantity(cart.lines.last.key, 3);

      expect(cart.quantityOfArticle('art-polo'), 4);
    });
  });

  group('exclusion bénéficiaire ⊕ niveau', () {
    test('poser un bénéficiaire efface le niveau déclaré', () {
      var cart = const BoutiqueCart().addArticle(_polo(), keyOf: _key);
      final key = cart.lines.single.key;
      cart = cart.setDeclaredLevel(key, 'primaire');

      cart = cart.setBeneficiary(key, _david);

      expect(cart.lines.single.declaredLevelId, isNull);
      // Et le prix suit le niveau de l'élève, pas celui qui avait été choisi.
      expect(cart.lines.single.unitPriceInCents, 1500);
    });

    test('un niveau déclaré est IGNORÉ tant qu\'un bénéficiaire est posé', () {
      // L'exclusion est tenue par le domaine, pas par l'écran : aucun chemin
      // — restauration d'un panier, rejeu — ne doit produire une ligne portant
      // les deux, sinon le prix dépendrait de qui l'a écrite en dernier.
      var cart = const BoutiqueCart().addArticle(_polo(), keyOf: _key);
      final key = cart.lines.single.key;
      cart = cart.setBeneficiary(key, _david);

      cart = cart.setDeclaredLevel(key, 'primaire');

      expect(cart.lines.single.declaredLevelId, isNull);
      expect(cart.lines.single.unitPriceInCents, 1500);
    });

    test('retirer le bénéficiaire fait réclamer un niveau', () {
      var cart = const BoutiqueCart().addArticle(_polo(), keyOf: _key);
      final key = cart.lines.single.key;
      cart = cart.setBeneficiary(key, _david);

      cart = cart.clearBeneficiary(key);

      expect(cart.lines.single.needsLevel, isTrue);
      expect(cart.lines.single.unitPriceInCents, isNull);
    });
  });

  group('totaux', () {
    test('une ligne non résolue compte pour zéro à l\'affichage', () {
      var cart = const BoutiqueCart().addArticle(_ecusson(), keyOf: _key);
      cart = cart.addArticle(_polo(), keyOf: _key); // sans niveau

      expect(cart.totalInCents, 1000);
      // Mais elle BLOQUE : sans cela le guichet encaisserait 10 $ pour ce
      // qu'il remet à 25 $.
      expect(cart.canCollect, isFalse);
    });

    test('le total est la somme des produits', () {
      var cart = const BoutiqueCart().addArticle(_polo(), keyOf: _key);
      cart = cart.setDeclaredLevel(cart.lines.single.key, 'humanites');
      cart = cart.setQuantity(cart.lines.single.key, 2);
      cart = cart.addArticle(_ecusson(), keyOf: _key);

      expect(cart.totalInCents, 1500 * 2 + 1000);
    });

    test('la quantité ne descend jamais sous 1', () {
      // Le retrait se fait par la corbeille : un compteur qui supprime surprend.
      var cart = const BoutiqueCart().addArticle(_ecusson(), keyOf: _key);

      cart = cart.setQuantity(cart.lines.single.key, 0);

      expect(cart.lines.single.quantity, 1);
      expect(cart.lines, hasLength(1));
    });
  });

  group('blocages nommés', () {
    test('panier vide : SEUL, les autres manques sont muets', () {
      const cart = BoutiqueCart();

      expect(cart.blockers.map((b) => b.kind), [CartBlockerKind.emptyCart]);
    });

    test('payeur entièrement vide : plus AUCUN blocage d\'identité', () {
      // Depuis la V114 serveur, l'identité du payeur ne conditionne plus
      // l'encaissement : ni nom, ni post-nom, ni prénom, ni même le fait
      // d'avoir un numéro. Seule la ligne sans niveau reste — elle, empêche
      // toujours de savoir COMBIEN encaisser.
      final cart = const BoutiqueCart()
          .addArticle(_polo(), keyOf: _key)
          .withPayer(const CartPayer());

      expect(cart.blockers.map((b) => b.kind), [
        CartBlockerKind.linesWithoutLevel,
      ]);
    });

    /// Le cas que la V114 a ouvert : quelqu'un achète un cahier, on ne lui
    /// demande rien, et la vente part. Aucune dette à rattacher, personne à
    /// recontacter — la contrepartie est remise sur-le-champ.
    test('panier garni, payeur entièrement vide : on encaisse', () {
      var cart = const BoutiqueCart().addArticle(_ecusson(), keyOf: _key);
      cart = cart.withPayer(const CartPayer());

      expect(cart.blockers, isEmpty);
      expect(cart.canCollect, isTrue);
    });

    test('téléphone entamé mais court : « incomplet », pas « absent »', () {
      final cart = const BoutiqueCart()
          .addArticle(_ecusson(), keyOf: _key)
          .withPayer(
            const CartPayer(
              lastName: 'Ndombo',
              middleName: 'Lelo',
              firstName: 'Willy',
              phoneNumber: '0810',
            ),
          );

      expect(cart.blockers.map((b) => b.kind), [
        CartBlockerKind.incompletePhone,
      ]);
    });

    test('les lignes sans niveau se comptent', () {
      var cart = const BoutiqueCart().withPayer(_payeurComplet);
      cart = cart.addArticle(_polo(), keyOf: _key);
      // La taille rend la ligne non fusionnable : la suivante s'empile.
      cart = cart.setSize(cart.lines.single.key, 'M');
      cart = cart.addArticle(_polo(), keyOf: _key);

      final blocker = cart.blockers.single;
      expect(blocker.kind, CartBlockerKind.linesWithoutLevel);
      expect(blocker.count, 2);
    });

    test('panier complet : aucun blocage', () {
      var cart = const BoutiqueCart().withPayer(_payeurComplet);
      cart = cart.addArticle(_ecusson(), keyOf: _key);

      expect(cart.blockers, isEmpty);
      expect(cart.canCollect, isTrue);
    });
  });

  group('multi-devises : détecté ET bloqué', () {
    // TESTS RETOURNÉS UNE SECONDE FOIS, par la branche multi-devises.
    //
    // Le 2026-08-29, la garde bloquante avait été retirée sur décision produit,
    // et ces tests épinglaient ce retrait — « le trou que la branche
    // multi-devises devra fermer », disait leur propre commentaire. C'est cette
    // branche-ci, et le trou se referme.
    //
    // Ce qu'il laissait passer : le contrat de vente porte un `totalInCents`
    // SCALAIRE, et l'invariant serveur (`totalInCents == Σ lineTotalInCents`)
    // est satisfait *numériquement* par la somme brute de deux unités. Un
    // panier USD + CDF était donc encaissé et **scellé** avec un total qui ne
    // veut rien dire, sans que rien ne le signale au caissier — et un ticket
    // scellé ne se corrige pas.
    test('deux devises n\'empêchent PAS d\'encaisser', () {
      // TEST RETOURNÉ une troisième fois, et cette fois par le contrat : la
      // vente porte `amounts[]` et chaque ligne SA devise. Un panier qui règle
      // 450,00 $ d'uniformes et 90 000 FC de manuels est un acte de caisse —
      // une vente, un reçu. Imposer deux gestes au caissier serait laisser le
      // schéma dicter le métier.
      var cart = const BoutiqueCart().withPayer(_payeurComplet);
      cart = cart.addArticle(_ecusson(), keyOf: _key);
      cart = cart.addArticle(
        _ecusson(currency: 'CDF', id: 'art-journal-cdf'),
        keyOf: _key,
      );

      expect(cart.canCollect, isTrue);
      expect(cart.blockers, isEmpty);
    });

    test('les totaux sont ventilés, jamais sommés', () {
      var cart = const BoutiqueCart().withPayer(_payeurComplet);
      cart = cart.addArticle(_ecusson(), keyOf: _key);
      cart = cart.addArticle(
        _ecusson(currency: 'CDF', id: 'art-journal-cdf'),
        keyOf: _key,
      );

      expect(cart.totals.isMultiCurrency, isTrue);
      expect(cart.totals.length, 2);
    });

    test('la devise du panier est NULLE quand il en mêle deux', () {
      // Elle valait « celle de la première ligne » : une unité choisie au
      // hasard de l'ordre d'ajout. Nulle, elle force l'appelant à lire
      // `totals` — qui, lui, dit la vérité.
      var cart = const BoutiqueCart().withPayer(_payeurComplet);
      cart = cart.addArticle(_ecusson(), keyOf: _key);
      cart = cart.addArticle(
        _ecusson(currency: 'CDF', id: 'art-journal-cdf'),
        keyOf: _key,
      );

      expect(cart.currency, isNull);
    });

    test(
      'le mélange reste DÉTECTABLE — c\'est sur quoi le blocage s\'appuie',
      () {
        var cart = const BoutiqueCart().withPayer(_payeurComplet);
        cart = cart.addArticle(_ecusson(), keyOf: _key);
        cart = cart.addArticle(
          _ecusson(currency: 'CDF', id: 'art-journal-cdf'),
          keyOf: _key,
        );

        expect(cart.isMultiCurrency, isTrue);
        expect(cart.currencies, {'USD', 'CDF'});
      },
    );

    test('une seule devise : rien à détecter', () {
      var cart = const BoutiqueCart().withPayer(_payeurComplet);
      cart = cart.addArticle(_ecusson(), keyOf: _key);
      cart = cart.addArticle(_polo(), keyOf: _key);
      cart = cart.setDeclaredLevel(cart.lines.last.key, 'primaire');

      expect(cart.isMultiCurrency, isFalse);
      expect(cart.currencies, {'USD'});
      expect(cart.canCollect, isTrue);
    });
  });

  group('payeur', () {
    test('la clé de rapprochement est les 9 derniers chiffres', () {
      const formats = [
        '0810220145',
        '+243 810 220 145',
        '243810220145',
        '+243-810-220-145',
      ];

      final keys = {
        for (final phone in formats) CartPayer(phoneNumber: phone).matchKey,
      };

      expect(keys, hasLength(1), reason: 'un numéro = un payeur');
      expect(keys.single, '810220145');
    });

    test('sous le seuil : aucune clé, donc aucune recherche', () {
      // On ne juge pas un numéro à moitié tapé.
      expect(const CartPayer(phoneNumber: '08102').matchKey, isNull);
    });

    test('le badge « connu » tombe dès que le numéro change', () {
      const connu = CartPayer(
        lastName: 'Ndombo',
        phoneNumber: '+243810220145',
        knownFromDirectory: true,
      );

      final modifie = connu.copyWith(phoneNumber: '+243810220146');

      expect(modifie.knownFromDirectory, isFalse);
    });

    test('corriger l\'orthographe ne casse PAS le rattachement', () {
      // La clé reste le numéro : les champs restent éditables après « Utiliser ».
      const connu = CartPayer(
        lastName: 'Ndombo',
        phoneNumber: '+243810220145',
        knownFromDirectory: true,
      );

      final corrige = connu.copyWith(lastName: 'Ndombu');

      expect(corrige.knownFromDirectory, isTrue);
    });
  });

  test('vider le panier emporte AUSSI le payeur', () {
    var cart = const BoutiqueCart().withPayer(_payeurComplet);
    cart = cart.addArticle(_ecusson(), keyOf: _key);

    cart = cart.cleared();

    expect(cart.isEmpty, isTrue);
    expect(cart.payer, const CartPayer());
  });
}
