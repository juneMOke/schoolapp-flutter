import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_catalog_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_local_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

BoutiqueArticleLocalModel _article(
  String id, {
  String year = 'ay-1',
  String pricingMode = 'PRIX_PAR_NIVEAU',
  Map<String, int> levelPrices = const {'lvl-1': 1000},
  int? unitPrice,
}) => BoutiqueArticleLocalModel(
  id: id,
  academicYearId: year,
  code: id.toUpperCase(),
  label: 'Article $id',
  family: 'UNIFORME',
  pricingMode: pricingMode,
  unitPriceInCents: unitPrice,
  levelPrices: levelPrices,
  currency: 'USD',
);

void main() {
  late Database db;
  late BoutiqueCatalogDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueCatalogDao(db);
  });
  tearDown(() async => db.close());

  test('un article descend avec sa grille, et se relit entier', () async {
    await dao.replaceArticlesForYears(
      [
        _article('polo', levelPrices: const {'lvl-1': 1000, 'lvl-2': 1500}),
      ],
      schoolId: 'E1',
      academicYearIds: const ['ay-1'],
    );

    final articles = await dao.articlesOfYear(
      schoolId: 'E1',
      academicYearId: 'ay-1',
    );

    expect(articles.single.levelPrices, {'lvl-1': 1000, 'lvl-2': 1500});
    expect(articles.single.pricingMode, 'PRIX_PAR_NIVEAU');
  });

  test('un article retiré du bundle disparaît, grille comprise', () async {
    // Le catalogue est REMPLACÉ, pas fusionné : l'absence d'une ligne EST
    // l'ordre de la retirer. Un article retiré de la vente côté serveur qui
    // resterait vendable au guichet ferait encaisser ce que l'école ne vend
    // plus.
    await dao.replaceArticlesForYears(
      [_article('polo'), _article('ecusson')],
      schoolId: 'E1',
      academicYearIds: const ['ay-1'],
    );

    await dao.replaceArticlesForYears(
      [_article('polo')],
      schoolId: 'E1',
      academicYearIds: const ['ay-1'],
    );

    final articles = await dao.articlesOfYear(
      schoolId: 'E1',
      academicYearId: 'ay-1',
    );
    expect(articles.map((a) => a.id), ['polo']);
    // La grille de l'article retiré part avec lui : une case orpheline se
    // rattacherait au prochain article de même identifiant.
    final orphans = await db.query(
      'ref_boutique_article_level_prices',
      where: 'article_id = ?',
      whereArgs: ['ecusson'],
    );
    expect(orphans, isEmpty);
  });

  test('une case retirée de la grille disparaît aussi', () async {
    await dao.replaceArticlesForYears(
      [
        _article('polo', levelPrices: const {'lvl-1': 1000, 'lvl-2': 1500}),
      ],
      schoolId: 'E1',
      academicYearIds: const ['ay-1'],
    );

    await dao.replaceArticlesForYears(
      [
        _article('polo', levelPrices: const {'lvl-1': 1000}),
      ],
      schoolId: 'E1',
      academicYearIds: const ['ay-1'],
    );

    final articles = await dao.articlesOfYear(
      schoolId: 'E1',
      academicYearId: 'ay-1',
    );
    // Sans cette purge, la caisse vendrait à un niveau dont le serveur ne veut
    // plus — et au prix d'hier.
    expect(articles.single.levelPrices, {'lvl-1': 1000});
  });

  group('purge scopée', () {
    test('aucune année fournie → upsert seul, rien n\'est purgé', () async {
      // C'est la porte de sortie du caviardage : quand le serveur n'a pas servi
      // la section, l'appelant ne fournit aucune année, et le catalogue local
      // survit.
      await dao.replaceArticlesForYears(
        [_article('polo')],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );

      await dao.replaceArticlesForYears(
        const [],
        schoolId: 'E1',
        academicYearIds: const [],
      );

      final articles = await dao.articlesOfYear(
        schoolId: 'E1',
        academicYearId: 'ay-1',
      );
      expect(articles, hasLength(1));
    });

    test('le catalogue d\'une AUTRE école n\'est jamais touché', () async {
      // « Une tablette, une école » a déjà produit dix flux à curseur nu.
      // Purger sans le scope effacerait ici le catalogue du second
      // établissement, qui vendrait alors sans savoir à quel prix.
      await dao.replaceArticlesForYears(
        [_article('polo')],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );
      await dao.replaceArticlesForYears(
        [_article('cahier')],
        schoolId: 'E2',
        academicYearIds: const ['ay-1'],
      );

      // E1 repousse un catalogue vide : seule SA ligne doit tomber.
      await dao.replaceArticlesForYears(
        const [],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );

      expect(
        await dao.articlesOfYear(schoolId: 'E1', academicYearId: 'ay-1'),
        isEmpty,
      );
      expect(
        await dao.articlesOfYear(schoolId: 'E2', academicYearId: 'ay-1'),
        hasLength(1),
      );
    });

    test('le catalogue d\'une AUTRE année n\'est pas touché', () async {
      await dao.replaceArticlesForYears(
        [_article('vieux', year: 'ay-0')],
        schoolId: 'E1',
        academicYearIds: const ['ay-0'],
      );

      await dao.replaceArticlesForYears(
        [_article('polo')],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );

      expect(
        await dao.articlesOfYear(schoolId: 'E1', academicYearId: 'ay-0'),
        hasLength(1),
      );
    });
  });

  test('countArticles compte par école et par année', () async {
    await dao.replaceArticlesForYears(
      [_article('polo'), _article('ecusson')],
      schoolId: 'E1',
      academicYearIds: const ['ay-1'],
    );

    expect(await dao.countArticles(schoolId: 'E1', academicYearId: 'ay-1'), 2);
    expect(await dao.countArticles(schoolId: 'E2', academicYearId: 'ay-1'), 0);
  });
}
