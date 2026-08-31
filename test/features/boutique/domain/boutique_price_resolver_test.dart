import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/boutique_price_resolver.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';

/// Les deux articles qui font la preuve de l'invariant I-1, repris du catalogue
/// réel de La Fontaine.
///
/// La Lacoste vaut **10 en primaire et 10 en CTEB** — deux niveaux qui
/// coïncident, ce qui est normal — et 15 en humanités. L'écusson vaut 10 lui
/// aussi, et il est vraiment plat. Rien dans les montants ne les distingue :
/// c'est `pricingMode` qui le fait, et lui seul.
BoutiqueArticle _lacoste() => const BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'A1',
  code: 'POLO',
  label: 'Polo Lacoste',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixParNiveau,
  levelPrices: {'primaire': 1000, 'cteb': 1000, 'humanites': 1500},
  currency: 'USD',
);

BoutiqueArticle _ecusson() => const BoutiqueArticle(
  id: 'art-ecu',
  academicYearId: 'A1',
  code: 'ECUS',
  label: 'Écusson brodé',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 1000,
  currency: 'USD',
);

/// Un article à grille dont TOUTES les cases coïncident : le piège exact que
/// l'inférence par les valeurs ne sait pas voir.
BoutiqueArticle _grilleUniforme() => const BoutiqueArticle(
  id: 'art-plate',
  academicYearId: 'A1',
  code: 'PLAT',
  label: 'Article à grille plate',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixParNiveau,
  levelPrices: {'primaire': 1000, 'cteb': 1000, 'humanites': 1000},
  currency: 'USD',
);

void main() {
  group('invariant I-1 — la variation se DÉCLARE', () {
    test('une grille dont toutes les cases valent 10 porte le badge', () {
      final article = _grilleUniforme();

      expect(article.showsLevelBadge, isTrue);
      expect(article.requiresLevel, isTrue);
      // Et la fourchette se réduit à un seul montant, sans que le badge tombe.
      expect(article.minPriceInCents, article.maxPriceInCents);
    });

    test('un prix unique de 10 ne porte JAMAIS le badge', () {
      final article = _ecusson();

      expect(article.showsLevelBadge, isFalse);
      expect(article.requiresLevel, isFalse);
    });

    test('les deux valent 10, et se comportent différemment', () {
      // Le cœur de l'invariant : à montants égaux, seule la déclaration
      // distingue « ne rien demander » de « exiger un niveau ».
      expect(_grilleUniforme().minPriceInCents, _ecusson().minPriceInCents);
      expect(_grilleUniforme().requiresLevel, isNot(_ecusson().requiresLevel));
    });
  });

  group('résolution du prix', () {
    test('prix unique : ni le niveau ni son absence ne changent rien', () {
      expect(BoutiquePriceResolver.resolve(_ecusson()), 1000);
      expect(
        BoutiquePriceResolver.resolve(_ecusson(), levelId: 'humanites'),
        1000,
      );
    });

    test('grille : le niveau donne le montant de sa case', () {
      expect(
        BoutiquePriceResolver.resolve(_lacoste(), levelId: 'primaire'),
        1000,
      );
      expect(
        BoutiquePriceResolver.resolve(_lacoste(), levelId: 'humanites'),
        1500,
      );
    });

    test('grille sans niveau : null, JAMAIS zéro', () {
      // Zéro s'additionnerait en silence et vendrait gratuitement ; null se
      // signale à l'écran et bloque l'encaissement.
      expect(BoutiquePriceResolver.resolve(_lacoste()), isNull);
      expect(BoutiquePriceResolver.resolve(_lacoste()), isNot(0));
    });

    test('grille avec un niveau absent de la grille : null', () {
      expect(
        BoutiquePriceResolver.resolve(_lacoste(), levelId: 'maternelle'),
        isNull,
      );
    });

    test('mode illisible : invendable, et surtout pas au prix unique', () {
      // Un serveur plus récent peut servir un mode que ce client ne connaît
      // pas. Le replier sur « prix unique » le vendrait sans demander le
      // niveau, donc au mauvais tarif.
      const inconnu = BoutiqueArticle(
        id: 'art-x',
        academicYearId: 'A1',
        code: 'X',
        label: 'Mode inconnu',
        family: ArticleFamily.uniforme,
        pricingMode: null,
        unitPriceInCents: 1000,
        currency: 'USD',
      );

      expect(inconnu.isSellable, isFalse);
      expect(BoutiquePriceResolver.resolve(inconnu), isNull);
      expect(
        BoutiquePriceResolver.resolve(inconnu, levelId: 'primaire'),
        isNull,
      );
    });
  });

  group('niveau effectif — l\'élève emporte son niveau', () {
    test('le bénéficiaire gagne sur le niveau déclaré', () {
      // Même arbitrage que le serveur, qui IGNORE `schoolLevelId` dès qu'un
      // bénéficiaire est nommé. Un arbitrage différent des deux côtés ferait
      // encaisser un prix et en enregistrer un autre.
      expect(
        BoutiquePriceResolver.effectiveLevelIdOf(
          beneficiaryLevelId: 'humanites',
          declaredLevelId: 'primaire',
        ),
        'humanites',
      );
    });

    test('sans bénéficiaire, le niveau déclaré fait foi (walk-in)', () {
      expect(
        BoutiquePriceResolver.effectiveLevelIdOf(declaredLevelId: 'primaire'),
        'primaire',
      );
    });

    test('ni l\'un ni l\'autre : null', () {
      expect(BoutiquePriceResolver.effectiveLevelIdOf(), isNull);
    });
  });

  group('needsLevel — réclamer un niveau n\'est pas manquer de prix', () {
    test('grille sans niveau : la ligne doit en réclamer un', () {
      expect(BoutiquePriceResolver.needsLevel(_lacoste()), isTrue);
    });

    test('grille avec un niveau hors grille : plus rien à réclamer', () {
      // Le niveau est choisi ; c'est le catalogue qui est troué. Redemander un
      // niveau enverrait le guichet corriger ce qui est déjà correct.
      expect(
        BoutiquePriceResolver.needsLevel(_lacoste(), levelId: 'maternelle'),
        isFalse,
      );
      expect(
        BoutiquePriceResolver.resolve(_lacoste(), levelId: 'maternelle'),
        isNull,
      );
    });

    test('prix unique : jamais', () {
      expect(BoutiquePriceResolver.needsLevel(_ecusson()), isFalse);
    });
  });
}
