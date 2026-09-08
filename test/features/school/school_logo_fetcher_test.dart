import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/school/data/local/school_logo_cache_dao.dart';
import 'package:school_app_flutter/features/school/data/school_logo_fetcher.dart';

import '../offline_full_db.dart';

// Le tirage conditionnel des octets du logo.
//
// ## Ce que ce fichier garde avant tout
//
// **L'`If-None-Match` se construit sur l'empreinte DÉTENUE, jamais sur celle que
// le lot annonce.** Bâti sur la cible, il produit un `304` définitif après un
// tirage raté : le serveur répond « rien de neuf » sur une empreinte qu'on n'a
// pas, et les octets n'arrivent jamais. L'état est stable, silencieux, sans
// erreur à montrer — et le logo reste absent pour toujours.
//
// Les tests regardent donc les EN-TÊTES RÉELLEMENT ENVOYÉS, pas seulement le
// contenu du cache après coup : un cache correct ne prouve pas qu'on a demandé
// correctement.

class _MockDio extends Mock implements Dio {}

const _held =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _target =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Uint8List _realBand() => File(
  'test/fixtures/logo/thermal_la_fontaine_576x128.png',
).readAsBytesSync();

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  late Database db;
  late SchoolLogoCacheDao cache;
  late _MockDio dio;
  late SchoolLogoFetcher fetcher;

  setUp(() async {
    db = await openFullOfflineDb();
    cache = SchoolLogoCacheDao(db);
    dio = _MockDio();
    fetcher = SchoolLogoFetcher(
      dio: dio,
      cache: cache,
      now: () => DateTime.utc(2026, 9, 8),
    );
  });
  tearDown(() async => db.close());

  Response<List<int>> response(int status, {List<int>? data, String? etag}) =>
      Response<List<int>>(
        requestOptions: RequestOptions(path: '/'),
        statusCode: status,
        data: data,
        headers: Headers.fromMap({
          if (etag != null) 'etag': [etag],
        }),
      );

  void stub(Response<List<int>> answer) {
    when(
      () => dio.get<List<int>>(any(), options: any(named: 'options')),
    ).thenAnswer((_) async => answer);
  }

  /// Les en-têtes réellement passés à Dio lors du dernier appel.
  Map<String, dynamic>? sentHeaders() {
    final captured = verify(
      () => dio.get<List<int>>(any(), options: captureAny(named: 'options')),
    ).captured;
    return (captured.last as Options).headers;
  }

  Future<void> run({
    SchoolLogoVariant variant = SchoolLogoVariant.thermal,
    String? target = _target,
  }) => fetcher.ensureFresh(
    schoolId: 'ecole-1',
    variant: variant,
    targetSha: target,
  );

  group('l\'en-tête conditionnel', () {
    /// ⚠️ **LE test.** Tablette neuve, rien en cache : aucun `If-None-Match` ne
    /// doit partir. C'est la seule façon d'obtenir un `200` — le contrat serveur
    /// le garantit par une assertion de son côté — et le seul chemin où un `304`
    /// laisserait la tablette sans image ET sans erreur.
    test('rien en cache : aucun en-tête conditionnel', () async {
      stub(response(200, data: _realBand(), etag: '"$_target"'));

      await run();

      expect(sentHeaders(), isNull);
      expect(
        await cache.findSha('ecole-1', SchoolLogoVariant.thermal),
        _target,
      );
    });

    /// ⚠️ L'en-tête porte ce qu'on DÉTIENT (`_held`), jamais ce que le lot
    /// annonce (`_target`). C'est précisément la confusion qui coûte le logo.
    test('en cache : l\'en-tête porte l\'empreinte DÉTENUE', () async {
      await cache.put(
        schoolId: 'ecole-1',
        variant: SchoolLogoVariant.thermal,
        sha256: _held,
        bytes: _realBand(),
        fetchedAt: DateTime.utc(2026),
      );
      stub(response(200, data: _realBand(), etag: '"$_target"'));

      await run();

      // ⚠️ Capturé UNE fois : `verify` consomme les interactions, et un second
      // appel ne trouverait plus rien à vérifier.
      final headers = sentHeaders();
      expect(headers!['If-None-Match'], _held);
      expect(headers['If-None-Match'], isNot(_target));
    });

    /// Rien à demander quand ce qu'on détient est déjà ce que le lot annonce :
    /// pas d'appel du tout, donc pas d'octets sur un réseau de terrain.
    test('déjà à jour : aucun appel', () async {
      await cache.put(
        schoolId: 'ecole-1',
        variant: SchoolLogoVariant.thermal,
        sha256: _target,
        bytes: _realBand(),
        fetchedAt: DateTime.utc(2026),
      );

      await run();

      verifyNever(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      );
    });
  });

  group('les réponses du serveur', () {
    test('200 range les octets et l\'empreinte servie', () async {
      stub(response(200, data: _realBand(), etag: '"$_target"'));

      await run();

      final cached = await cache.find('ecole-1', SchoolLogoVariant.thermal);
      expect(cached!.sha256, _target);
      expect(cached.bytes, equals(_realBand()));
    });

    /// L'ETag est servi entre guillemets et stocké **nu** : c'est sous cette
    /// forme qu'il arrive dans le lot référentiel, et les deux doivent se
    /// comparer sans normalisation à chaque lecture.
    test('les guillemets et le W/ de l\'ETag sont retirés', () async {
      stub(response(200, data: _realBand(), etag: 'W/"$_target"'));

      await run();

      expect(
        await cache.findSha('ecole-1', SchoolLogoVariant.thermal),
        _target,
      );
    });

    test('304 laisse le cache intact', () async {
      await cache.put(
        schoolId: 'ecole-1',
        variant: SchoolLogoVariant.thermal,
        sha256: _held,
        bytes: _realBand(),
        fetchedAt: DateTime.utc(2026),
      );
      stub(response(304));

      await run();

      expect(await cache.findSha('ecole-1', SchoolLogoVariant.thermal), _held);
    });

    /// Le serveur fait autorité sur le lot : s'il ne sert plus de logo, la
    /// tablette cesse d'en imprimer un. Le garder ferait ressortir un sceau que
    /// l'école a retiré, indéfiniment et hors ligne.
    test('404 retire la ligne', () async {
      await cache.put(
        schoolId: 'ecole-1',
        variant: SchoolLogoVariant.thermal,
        sha256: _held,
        bytes: _realBand(),
        fetchedAt: DateTime.utc(2026),
      );
      stub(response(404));

      await run();

      expect(await cache.find('ecole-1', SchoolLogoVariant.thermal), isNull);
    });

    /// Un droit manquant n'est pas une raison d'effacer ce que la tablette a
    /// déjà servi hors ligne.
    test('403 ne touche à rien', () async {
      await cache.put(
        schoolId: 'ecole-1',
        variant: SchoolLogoVariant.thermal,
        sha256: _held,
        bytes: _realBand(),
        fetchedAt: DateTime.utc(2026),
      );
      stub(response(403));

      await run();

      expect(await cache.findSha('ecole-1', SchoolLogoVariant.thermal), _held);
    });

    test('un réseau coupé laisse le cache tel quel', () async {
      await cache.put(
        schoolId: 'ecole-1',
        variant: SchoolLogoVariant.thermal,
        sha256: _held,
        bytes: _realBand(),
        fetchedAt: DateTime.utc(2026),
      );
      when(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));

      await run();

      expect(await cache.findSha('ecole-1', SchoolLogoVariant.thermal), _held);
    });
  });

  group('ce qui n\'entre pas en cache', () {
    /// ⚠️ Le garde qui ferme la boucle. Ranger des octets tronqués avec
    /// l'empreinte annoncée ferait prétendre à la tablette qu'elle détient une
    /// image qu'elle n'a pas : le prochain `If-None-Match` obtiendrait `304`, et
    /// le logo resterait absent **pour toujours**, sans erreur nulle part.
    test('une bande tronquée n\'est pas rangée', () async {
      final truncated = _realBand().sublist(0, 400);
      stub(response(200, data: truncated, etag: '"$_target"'));

      await run();

      expect(await cache.find('ecole-1', SchoolLogoVariant.thermal), isNull);
    });

    test('des octets qui ne sont pas un PNG n\'entrent pas', () async {
      stub(response(200, data: const [1, 2, 3, 4], etag: '"$_target"'));

      await run(variant: SchoolLogoVariant.display);

      expect(await cache.find('ecole-1', SchoolLogoVariant.display), isNull);
    });

    test('une réponse vide n\'entre pas', () async {
      stub(response(200, data: const [], etag: '"$_target"'));

      await run();

      expect(await cache.find('ecole-1', SchoolLogoVariant.thermal), isNull);
    });
  });

  group('l\'école qui n\'a pas de logo', () {
    /// Empreinte absente dans le lot : le sceau a été retiré. La ligne part, et
    /// aucun appel n'est fait — il n'y a rien à demander.
    test('empreinte nulle : la ligne part, sans appel', () async {
      await cache.put(
        schoolId: 'ecole-1',
        variant: SchoolLogoVariant.thermal,
        sha256: _held,
        bytes: _realBand(),
        fetchedAt: DateTime.utc(2026),
      );

      await run(target: null);

      expect(await cache.find('ecole-1', SchoolLogoVariant.thermal), isNull);
      verifyNever(
        () => dio.get<List<int>>(any(), options: any(named: 'options')),
      );
    });
  });
}
