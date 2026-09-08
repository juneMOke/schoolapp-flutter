import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/referential_pull_models.dart';
import 'package:school_app_flutter/features/school/data/local/school_logo_cache_dao.dart';

import '../offline_full_db.dart';

/// Le logo de l'école : sa descente par le lot référentiel, et son cache local.
///
/// Deux empreintes coexistent dans ce système, et **les confondre coûte le
/// logo** : celle de `ref_school` dit ce que l'école A, celle de
/// `school_logo_cache` ce que la tablette DÉTIENT. Ces tests fixent laquelle
/// vient d'où.
const _sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _shaOther =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

Map<String, dynamic> _bundleJson({Object? logoRefs = _absent}) => {
  'school': const {
    'id': 'ecole-1',
    'name': 'Complexe scolaire La Colombe',
    'city': 'Kinshasa',
  },
  'current': {
    'academicYear': const {
      'id': 'y-1',
      'name': '2025-2026',
      'startDate': '2025-09-01',
      'endDate': '2026-07-31',
      'isCurrent': true,
    },
    'schoolLevelGroups': const <Map<String, dynamic>>[],
    'schoolLevels': const <Map<String, dynamic>>[],
  },
  'previous': null,
  if (!identical(logoRefs, _absent)) 'logoRefs': logoRefs,
  'serverTime': '2026-09-08T01:12:33.481Z',
};

const Object _absent = Object();

void main() {
  group('le lot référentiel', () {
    /// La forme réelle, telle que le back la sert : objet **frère** de `school`,
    /// à la racine. Jamais dedans, et jamais aplati à la racine.
    test('lit les deux empreintes à la RACINE du lot', () {
      final bundle = ReferentialBundleDto.fromJson(
        _bundleJson(
          logoRefs: const {'displaySha256': _sha, 'thermalSha256': _shaOther},
        ),
      );

      expect(bundle.logoRefs, isNotNull);
      expect(bundle.logoRefs!.displaySha256, _sha);
      expect(bundle.logoRefs!.thermalSha256, _shaOther);
    });

    /// ⚠️ La nuance qui ne se devine pas : une école sans logo reçoit la clé
    /// **PRÉSENTE et nulle**, pas une clé absente. Le projet serveur n'a aucune
    /// politique globale d'inclusion, donc rien ne se déduit d'une règle
    /// générale — la désérialisation teste la VALEUR.
    test('une école sans logo : clé présente et nulle', () {
      final bundle = ReferentialBundleDto.fromJson(_bundleJson(logoRefs: null));
      expect(bundle.logoRefs, isNull);
    });

    /// Le pendant défensif : une charge utile qui omettrait le champ ne doit pas
    /// lever. Ce n'est pas la forme servie, mais rien ne doit en dépendre.
    test('un lot sans le champ du tout ne lève pas', () {
      final bundle = ReferentialBundleDto.fromJson(_bundleJson());
      expect(bundle.logoRefs, isNull);
    });

    /// ⚠️ Les empreintes ne doivent PAS être lues dans l'objet école. Côté
    /// serveur, `SchoolDto` est aussi le corps du `PUT`, et y loger des valeurs
    /// dérivées ouvrirait un chemin pour en déposer une forgée. Le back épingle
    /// l'absence des quatre formes dérivables par erreur ; celle-ci est la
    /// nôtre.
    test('des empreintes glissées DANS l\'école sont ignorées', () {
      final json = _bundleJson();
      json['school'] = {
        ...json['school']! as Map<String, dynamic>,
        'logoThermalSha256': _sha,
        'logoDisplaySha256': _sha,
      };

      final bundle = ReferentialBundleDto.fromJson(json);
      expect(bundle.logoRefs, isNull);
    });
  });

  group('l\'écriture dans ref_school', () {
    late Database db;
    late EnrollmentReferentialDao dao;

    setUp(() async {
      db = await openFullOfflineDb();
      dao = EnrollmentReferentialDao(db);
    });
    tearDown(() async => db.close());

    Future<List<Map<String, Object?>>> schoolRows() => db.query(
      'ref_school',
      columns: const ['logo_thermal_sha256', 'logo_display_sha256'],
    );

    test('les empreintes du lot atterrissent dans les deux colonnes', () async {
      await dao.upsertReferential(
        ReferentialBundleDto.fromJson(
          _bundleJson(
            logoRefs: const {'displaySha256': _sha, 'thermalSha256': _shaOther},
          ),
        ),
        syncedAt: 0,
        schoolId: 'ecole-1',
      );

      final rows = await schoolRows();
      expect(rows.single['logo_thermal_sha256'], _shaOther);
      expect(rows.single['logo_display_sha256'], _sha);
    });

    test('sans logo, les deux colonnes restent nulles', () async {
      await dao.upsertReferential(
        ReferentialBundleDto.fromJson(_bundleJson(logoRefs: null)),
        syncedAt: 0,
        schoolId: 'ecole-1',
      );

      final rows = await schoolRows();
      expect(rows.single['logo_thermal_sha256'], isNull);
      expect(rows.single['logo_display_sha256'], isNull);
    });
  });

  group('le cache d\'octets', () {
    late Database db;
    late SchoolLogoCacheDao dao;

    setUp(() async {
      db = await openFullOfflineDb();
      dao = SchoolLogoCacheDao(db);
    });
    tearDown(() async => db.close());

    Uint8List bytesOf(int n) =>
        Uint8List.fromList(List<int>.generate(n, (i) => i % 256));

    Future<void> put(
      String school,
      SchoolLogoVariant variant,
      String sha,
      int size,
    ) => dao.put(
      schoolId: school,
      variant: variant,
      sha256: sha,
      bytes: bytesOf(size),
      fetchedAt: DateTime.utc(2026, 9, 8),
    );

    /// Les octets doivent revenir **à l'identique**. Tronqués ou ré-encodés, la
    /// comparaison d'empreinte serait fausse au démarrage suivant et le logo se
    /// retéléchargerait en boucle, sans que rien ne le signale.
    test('les octets font l\'aller-retour intacts', () async {
      await put('ecole-1', SchoolLogoVariant.thermal, _sha, 512);

      final cached = await dao.find('ecole-1', SchoolLogoVariant.thermal);
      expect(cached!.sha256, _sha);
      expect(cached.bytes, equals(bytesOf(512)));
    });

    test('rien en cache : les deux lectures rendent null', () async {
      expect(await dao.findSha('ecole-1', SchoolLogoVariant.display), isNull);
      expect(await dao.find('ecole-1', SchoolLogoVariant.display), isNull);
    });

    /// C'est cette lecture qui construit l'`If-None-Match` : elle porte ce que
    /// la tablette DÉTIENT, jamais ce que le lot annonce.
    test('findSha rend l\'empreinte détenue', () async {
      await put('ecole-1', SchoolLogoVariant.display, _sha, 32);
      expect(await dao.findSha('ecole-1', SchoolLogoVariant.display), _sha);
    });

    /// Le remplacement écrit la ligne ENTIÈRE. C'est la règle qui a vidé
    /// `pdf_blob` quand elle n'était pas tenue : une écriture partielle sous
    /// `replace` remet les colonnes omises à NULL sans rien signaler.
    test('remplacer une variante garde ses octets cohérents', () async {
      await put('ecole-1', SchoolLogoVariant.thermal, _sha, 64);
      await put('ecole-1', SchoolLogoVariant.thermal, _shaOther, 128);

      final cached = await dao.find('ecole-1', SchoolLogoVariant.thermal);
      expect(cached!.sha256, _shaOther);
      expect(cached.bytes, equals(bytesOf(128)));
      expect(
        await db.query('school_logo_cache'),
        hasLength(1),
        reason: 'la clé composite doit remplacer, pas dupliquer',
      );
    });

    /// Les deux variantes sont **indépendantes** : un tirage `thermal` réussi et
    /// un `display` en échec laissent le ticket avec son logo et l'écran avec
    /// son repli. C'est l'argument pour une ligne par variante.
    test('les deux variantes ne se marchent pas dessus', () async {
      await put('ecole-1', SchoolLogoVariant.thermal, _sha, 16);
      await put('ecole-1', SchoolLogoVariant.display, _shaOther, 32);

      expect(
        (await dao.find('ecole-1', SchoolLogoVariant.thermal))!.bytes,
        hasLength(16),
      );
      expect(
        (await dao.find('ecole-1', SchoolLogoVariant.display))!.bytes,
        hasLength(32),
      );
    });

    test('deux écoles gardent chacune son logo', () async {
      await put('ecole-1', SchoolLogoVariant.thermal, _sha, 16);
      await put('ecole-2', SchoolLogoVariant.thermal, _shaOther, 32);

      expect(
        await dao.findSha('ecole-2', SchoolLogoVariant.thermal),
        _shaOther,
      );

      expect(await dao.deleteForeignSchools('ecole-2'), 1);
      expect(await dao.findSha('ecole-1', SchoolLogoVariant.thermal), isNull);
      expect(
        await dao.findSha('ecole-2', SchoolLogoVariant.thermal),
        _shaOther,
      );
    });

    /// La contrainte de stockage, doublée en SQL : la variante `print` du
    /// serveur n'a rien à faire sur une tablette.
    test('une variante hors du domaine est refusée par la base', () async {
      expect(
        db.insert('school_logo_cache', {
          'school_id': 'ecole-1',
          'variant': 'print',
          'sha256': _sha,
          'bytes': bytesOf(4),
          'fetched_at': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
