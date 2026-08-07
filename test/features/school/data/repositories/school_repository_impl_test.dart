import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
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

  setUp(() async {
    db = await openFullOfflineDb();
    currentUser = CurrentUserContext()..set('u1', schoolId: 'school-1');
    repository = SchoolRepositoryImpl(
      referentialDao: EnrollmentReferentialDao(db),
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
}
