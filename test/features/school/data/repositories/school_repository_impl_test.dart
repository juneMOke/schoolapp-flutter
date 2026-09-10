import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/school/data/local/school_logo_cache_dao.dart';
import 'package:school_app_flutter/features/school/data/repositories/school_repository_impl.dart';

import '../../../offline_full_db.dart';

void main() {
  late Database db;
  late CurrentUserContext currentUser;
  late SchoolRepositoryImpl repository;

  Future<void> seedSchool({
    required String id,
    String name = 'Complexe Scolaire La Colombe',
    String? city = 'Kinshasa',
    String? municipality,
  }) {
    return db.insert('ref_school', {
      'id': id,
      'name': name,
      'city': city,
      'municipality': municipality,
      'synced_at': 0,
    });
  }

  // Une empreinte de la bonne LONGUEUR : le repository ne la vérifie pas, mais
  // un test qui la rendrait courte laisserait croire que la colonne l'accepte.
  const logoSha =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  Future<void> seedLogo({
    required String schoolId,
    SchoolLogoVariant variant = SchoolLogoVariant.display,
    String sha256 = logoSha,
    List<int> bytes = const [137, 80, 78, 71],
  }) {
    return db.insert('school_logo_cache', {
      'school_id': schoolId,
      'variant': variant.dbValue,
      'sha256': sha256,
      'bytes': Uint8List.fromList(bytes),
      'fetched_at': 0,
    });
  }

  setUp(() async {
    db = await openFullOfflineDb();
    currentUser = CurrentUserContext()..set('u1', schoolId: 'school-1');
    repository = SchoolRepositoryImpl(
      referentialDao: EnrollmentReferentialDao(db),
      logoCache: SchoolLogoCacheDao(db),
      currentUser: currentUser,
    );
  });

  tearDown(() async => db.close());

  test('renvoie l\'identité de l\'école de la session', () async {
    await seedSchool(id: 'school-1');

    final result = await repository.loadCurrentSchool();

    final school = result.getOrElse(() => null);
    expect(school?.name, 'Complexe Scolaire La Colombe');
    expect(school?.locality, 'Kinshasa');
  });

  test(
    'référentiel non encore pullé → identité inconnue, pas un échec',
    () async {
      final result = await repository.loadCurrentSchool();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null), isNull);
    },
  );

  test('aucune session → identité inconnue', () async {
    await seedSchool(id: 'school-1');
    currentUser.clear();

    final result = await repository.loadCurrentSchool();

    expect(result.getOrElse(() => null), isNull);
  });

  test(
    'device multi-école : une ligne d\'une AUTRE école n\'est jamais servie',
    () async {
      // `ref_school` est mono-ligne et réécrite à chaque pull : après un pull
      // fait pour une autre école, elle ne décrit plus la session courante.
      await seedSchool(id: 'school-2', name: 'Institut Voisin');

      final result = await repository.loadCurrentSchool();

      expect(result.getOrElse(() => null), isNull);
    },
  );

  test('sans ville, la commune fait office de localité', () async {
    await seedSchool(id: 'school-1', city: null, municipality: 'Gombe');

    final result = await repository.loadCurrentSchool();

    expect(result.getOrElse(() => null)?.locality, 'Gombe');
  });

  group('sceau de l\'école', () {
    test('rend les octets détenus et leur empreinte', () async {
      await seedLogo(schoolId: 'school-1', bytes: const [1, 2, 3]);

      final result = await repository.loadCurrentSchoolLogo();

      final logo = result.getOrElse(() => null);
      expect(logo?.sha256, logoSha);
      expect(logo?.bytes, Uint8List.fromList(const [1, 2, 3]));
    });

    test('aucune ligne en cache → pas de sceau, pas un échec', () async {
      final result = await repository.loadCurrentSchoolLogo();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null), isNull);
    });

    test('aucune session → pas de sceau', () async {
      await seedLogo(schoolId: 'school-1');
      currentUser.clear();

      final result = await repository.loadCurrentSchoolLogo();

      expect(result.getOrElse(() => null), isNull);
    });

    test('le sceau d\'une AUTRE école n\'est jamais servi', () async {
      await seedLogo(schoolId: 'school-2');

      final result = await repository.loadCurrentSchoolLogo();

      expect(result.getOrElse(() => null), isNull);
    });

    test('la variante thermique ne sert JAMAIS de sceau d\'écran', () async {
      // Un PNG 1 bit 576×128 destiné au papier : posé à l'écran, il donnerait
      // une bande noire là où l'on attend un logo.
      await seedLogo(schoolId: 'school-1', variant: SchoolLogoVariant.thermal);

      final result = await repository.loadCurrentSchoolLogo();

      expect(result.getOrElse(() => null), isNull);
    });

    test(
      'un référentiel décrivant une autre école ne retire pas le sceau',
      () async {
        // `ref_school` est mono-ligne : elle peut décrire l'école du dernier
        // pull, pas celle de la session. Le cache de logos, lui, est claveté
        // par école — le sceau reste donc juste quand le nom se tait.
        await seedSchool(id: 'school-2', name: 'Institut Voisin');
        await seedLogo(schoolId: 'school-1');

        expect(
          (await repository.loadCurrentSchool()).getOrElse(() => null),
          isNull,
        );
        expect(
          (await repository.loadCurrentSchoolLogo()).getOrElse(() => null),
          isNotNull,
        );
      },
    );
  });
}
