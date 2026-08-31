import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_catalog_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_catalog_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

const _catalogRead = 'boutique.catalog.read';
const _saleRead = 'boutique.sale.read';

BoutiqueArticleLocalModel _article(
  String id, {
  String family = 'UNIFORME',
  String pricingMode = 'PRIX_UNIQUE',
  int? unitPrice = 1000,
  Map<String, int> levelPrices = const {},
  String label = 'Article',
}) => BoutiqueArticleLocalModel(
  id: id,
  academicYearId: 'ay-1',
  code: id.toUpperCase(),
  label: label,
  family: family,
  pricingMode: pricingMode,
  unitPriceInCents: unitPrice,
  levelPrices: levelPrices,
  currency: 'USD',
);

void main() {
  late Database db;
  late BoutiqueCatalogDao dao;

  BoutiqueCatalogRepositoryImpl repoWith(List<String>? permissions) =>
      BoutiqueCatalogRepositoryImpl(
        dao: dao,
        currentUser: CurrentUserContext()..set('u1', schoolId: 'E1'),
        permissions: () => permissions,
      );

  Future<BoutiqueCatalog> catalogOf(List<String>? permissions) async {
    final result = await repoWith(permissions).catalogOfYear('ay-1');
    return result.getOrElse(() => throw StateError('left'));
  }

  setUp(() async {
    db = await openFullOfflineDb();
    dao = BoutiqueCatalogDao(db);
  });
  tearDown(() async => db.close());

  group('les deux vides ne se ressemblent pas', () {
    test('sans `boutique.catalog.read` → retenu, jamais « vide »', () async {
      // Le serveur caviarde la section à `null`. Le confondre avec un catalogue
      // vide ferait conclure au guichet que l'école n'a rien paramétré, alors
      // qu'il lui manque un droit — et personne n'irait chercher de ce côté.
      await dao.replaceArticlesForYears(
        [_article('polo')],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );

      final catalog = await catalogOf(const [_saleRead]);

      expect(catalog.withheld, isTrue);
      expect(catalog.articles, isEmpty);
    });

    test('avec le droit et aucun article → vide, non retenu', () async {
      final catalog = await catalogOf(const [_catalogRead, _saleRead]);

      expect(catalog.withheld, isFalse);
      expect(catalog.isEmpty, isTrue);
    });

    test('droits INCONNUS (null) → retenu, fail-closed', () async {
      // Ensemble jamais renseigné : on ne montre pas un catalogue au motif
      // qu'on ignore les droits.
      final catalog = await catalogOf(null);

      expect(catalog.withheld, isTrue);
    });
  });

  group('lecture du catalogue', () {
    setUp(() async {
      await dao.replaceArticlesForYears(
        [
          _article('polo', label: 'Polo', family: 'UNIFORME'),
          _article('cahier', label: 'Cahier', family: 'FOURNITURES'),
          _article('promenade', label: 'Promenade', family: 'ACTIVITES'),
          _article('chemise', label: 'Chemise', family: 'UNIFORME'),
        ],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );
    });

    test('les articles se traduisent en entités du domaine', () async {
      final catalog = await catalogOf(const [_catalogRead]);

      expect(catalog.articles, hasLength(4));
      expect(catalog.articles.first.pricingMode, PricingMode.prixUnique);
    });

    test('les groupes sortent dans l\'ordre de l\'énumération', () async {
      // Jamais l'alphabet : ACTIVITES arriverait alors avant UNIFORME, et le
      // guichet perdrait le repère qu'il a appris.
      final catalog = await catalogOf(const [_catalogRead]);

      expect(catalog.byFamily.keys.toList(), [
        ArticleFamily.uniforme,
        ArticleFamily.fournitures,
        ArticleFamily.activites,
      ]);
    });

    test('une famille sans article ne laisse aucun intitulé', () async {
      final catalog = await catalogOf(const [_catalogRead]);

      expect(catalog.byFamily.containsKey(ArticleFamily.actes), isFalse);
    });

    test('les articles d\'un groupe sont triés par libellé', () async {
      final catalog = await catalogOf(const [_catalogRead]);

      expect(catalog.byFamily[ArticleFamily.uniforme]!.map((a) => a.label), [
        'Chemise',
        'Polo',
      ]);
    });
  });

  group('ce que ce client ne sait pas vendre', () {
    test('un mode inconnu sort du catalogue vendable, et se dit', () async {
      // Un serveur plus récent peut servir un mode inédit. Le vendre au prix
      // unique par défaut le vendrait sans demander le niveau ; le jeter en
      // silence enverrait le guichet chercher un article que la direction jure
      // avoir créé.
      await dao.replaceArticlesForYears(
        [_article('polo'), _article('mystere', pricingMode: 'PRIX_AU_POIDS')],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );

      final catalog = await catalogOf(const [_catalogRead]);

      expect(catalog.unsellable.map((a) => a.id), ['mystere']);
      expect(catalog.byFamily[ArticleFamily.uniforme]!.map((a) => a.id), [
        'polo',
      ]);
    });

    test('une famille inconnue laisse l\'article VENDABLE', () async {
      // Son prix ne dépend pas de sa famille : le rendre invendable pour un
      // libellé de groupe coûterait une vente pour rien.
      await dao.replaceArticlesForYears(
        [_article('bizarre', family: 'DIVERS')],
        schoolId: 'E1',
        academicYearIds: const ['ay-1'],
      );

      final catalog = await catalogOf(const [_catalogRead]);

      expect(catalog.articles.single.isSellable, isTrue);
      expect(catalog.articles.single.family, isNull);
      // Mais il ne s'invente pas de groupe.
      expect(catalog.byFamily, isEmpty);
    });
  });

  test('une base illisible rend une Failure, pas un catalogue vide', () async {
    await db.close();

    final result = await repoWith(const [_catalogRead]).catalogOfYear('ay-1');

    expect(result.isLeft(), isTrue);
    expect(result.fold((f) => f, (_) => null), isA<StorageFailure>());
    // Puis rouvrir pour que le tearDown ne double pas la fermeture.
    db = await openFullOfflineDb();
  });
}
