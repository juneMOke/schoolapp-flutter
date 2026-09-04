import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/di/offline_injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/local/auth_local_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_enrollment_duplicates_use_case.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../features/offline_full_db.dart';

class _MockAuthSessionManager extends Mock implements AuthSessionManager {}

class _AlwaysOffline implements ConnectivityService {
  @override
  Future<bool> isOnline() async => false;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

/// Le **câblage** de la sonde de doublon, et sa chaîne complète jusqu'à sqflite.
///
/// Chaque couche est prouvée ailleurs, sur des instances construites à la main.
/// C'est nécessaire et insuffisant : `EnrollmentStepperScope` résout la sonde
/// par `getIt<ProbeEnrollmentDuplicatesUseCase>()`, et un enregistrement oublié
/// ne fait broncher ni l'analyseur ni aucun test de comportement — il lève à
/// l'ouverture du wizard, au guichet.
///
/// Ce fichier joue donc le scénario du terrain de bout en bout, sur une vraie
/// base : un ancien élève re-saisi à neuf en Première inscription.
void main() {
  late Database db;
  late GetIt getIt;

  const year = 'ay-2026';

  setUp(() async {
    db = await openFullOfflineDb();
    getIt = GetIt.asNewInstance();

    getIt.registerSingleton<Database>(db);
    getIt.registerSingleton<Map<String, dynamic>>(<String, dynamic>{});
    getIt.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
    getIt.registerSingleton<Dio>(Dio());
    getIt.registerSingleton<CurrentUserContext>(CurrentUserContext());
    getIt.registerSingleton<IdGenerator>(const IdGenerator(Uuid()));
    getIt.registerSingleton<SyncMetaDao>(SyncMetaDao(db));
    getIt.registerSingleton<AuthLocalDao>(AuthLocalDao(db));
    getIt.registerSingleton<ConnectivityService>(_AlwaysOffline());
    getIt.registerSingleton<SyncEngine>(
      SyncEngine(outbox: OutboxDao(db), connectivity: _AlwaysOffline()),
    );
    getIt.registerSingleton<PullCoordinator>(
      PullCoordinator(connectivity: _AlwaysOffline()),
    );
    getIt.registerSingleton<AuthSessionManager>(_MockAuthSessionManager());
    getIt.registerSingleton<DeviceIdentityService>(
      const DeviceIdentityService(FlutterSecureStorage(), Uuid()),
    );

    registerOfflineModules(getIt);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  Future<void> insertCurrentYear() => db.insert('ref_academic_years', {
    'id': year,
    'name': '2026-2027',
    'is_current': 1,
    'school_id': 'sch-1',
  });

  Future<void> insertEnrolled({
    required String studentId,
    required String enrollmentId,
    String lastName = 'Mukendi',
    String firstName = 'Jean',
    String surname = 'Kabeya',
    String dateOfBirth = '2015-03-04',
  }) async {
    await db.insert('students', {
      'id': studentId,
      'first_name': firstName,
      'last_name': lastName,
      'surname': surname,
      'gender': 'MALE',
      'date_of_birth': dateOfBirth,
      'updated_at': 100,
    });
    await db.insert('enrollments', {
      'id': enrollmentId,
      'student_id': studentId,
      'enrollment_type': 'NEW_ENROLLMENT',
      'status': 'COMPLETED',
      'academic_year_id': year,
      'enrollment_date': '2026-09-01',
      'sync_status': 'SYNCED',
      'updated_at': 100,
    });
  }

  Future<void> insertCohort({
    required String studentId,
    String lastName = 'Mukendi',
    String firstName = 'Jean',
    String surname = 'Kabeya',
    String dateOfBirth = '2015-03-04',
  }) => db.insert('ref_previous_year_students', {
    'student_id': studentId,
    'matriculation_number': 'MAT-$studentId',
    'first_name': firstName,
    'last_name': lastName,
    'surname': surname,
    'gender': 'MALE',
    'date_of_birth': dateOfBirth,
  });

  /// Ce que le guichet vient de taper à l'étape Identité.
  const typed = EnrollmentIdentity(
    lastName: 'Mukendi',
    firstName: 'Jean',
    surname: 'Kabeya',
    dateOfBirth: '2015-03-04',
  );

  Future<List<EnrollmentDuplicateCandidate>> probe({
    String? academicYearId,
  }) async {
    final result = await getIt<ProbeEnrollmentDuplicatesUseCase>()(
      typed: typed,
      studentId: 'self',
      enrollmentId: 'self-e',
      academicYearId: academicYearId,
    );
    return result.getOrElse(() => throw StateError('attendu Right'));
  }

  test('la sonde se résout depuis le conteneur RÉEL', () {
    expect(() => getIt<ProbeEnrollmentDuplicatesUseCase>(), returnsNormally);
  });

  test(
    'la chaîne va jusqu\'à la base : une base vide ne fait pas d\'erreur',
    () async {
      await insertCurrentYear();

      // « Rien à dire » n'est pas « la base est illisible » : la sonde se tait,
      // elle ne tombe pas.
      expect(await probe(), isEmpty);
    },
  );

  test('le scénario du terrain : l\'ancien élève re-saisi à neuf', () async {
    await insertCurrentYear();
    // Cet enfant était là l'an dernier. L'agent ne l'a pas trouvé dans le
    // vivier, et le re-saisit en Première inscription — en inversant au passage
    // le nom et le post-nom, comme cela arrive.
    await insertCohort(
      studentId: 'ancien',
      lastName: 'Kabeya',
      surname: 'Mukendi',
    );
    // Et un autre enfant, déjà inscrit cette année, porte exactement la même
    // identité que ce qui vient d'être tapé.
    await insertEnrolled(studentId: 'deja', enrollmentId: 'deja-e');
    // Un troisième, sans rapport, ne doit pas remonter.
    await insertEnrolled(
      studentId: 'tiers',
      enrollmentId: 'tiers-e',
      lastName: 'Ilunga',
      firstName: 'Marie',
      surname: 'Tshibangu',
    );

    final found = await probe();

    expect([for (final c in found) c.studentId], ['deja', 'ancien']);
    expect(found.first.level, EnrollmentDuplicateLevel.certain);
    expect(found.first.source, EnrollmentDuplicateSource.currentYearDossier);
    expect(found.first.enrollmentId, 'deja-e');
    // L'inversion nom ↔ post-nom est bien vue, à travers toute la chaîne.
    expect(found.last.level, EnrollmentDuplicateLevel.probable);
    expect(found.last.source, EnrollmentDuplicateSource.previousYearCohort);
    expect(found.last.enrollmentId, isNull);
  });

  test('le brouillon en cours ne se trouve pas lui-même', () async {
    await insertCurrentYear();
    // Le dossier qu'on est en train de saisir EST en base depuis
    // l'enregistrement de l'étape Identité, avec exactement cette identité.
    await insertEnrolled(studentId: 'self', enrollmentId: 'self-e');

    expect(await probe(), isEmpty);
  });

  test('l\'année non résolue laisse la cohorte parler seule', () async {
    // Aucune ligne `ref_academic_years` : le référentiel n'est pas descendu.
    await insertCohort(studentId: 'ancien');
    await insertEnrolled(studentId: 'deja', enrollmentId: 'deja-e');

    final found = await probe();

    expect([for (final c in found) c.studentId], ['ancien']);
  });

  /// Empreinte du **contenu entier** de la base, table par table. Un simple
  /// compte de lignes laisserait passer un `UPDATE` ; l'empreinte, non.
  Future<Map<String, String>> databaseFingerprint() async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    final fingerprint = <String, String>{};
    for (final table in tables) {
      final name = table['name'] as String;
      fingerprint[name] = (await db.rawQuery(
        'SELECT * FROM "$name"',
      )).toString();
    }
    return fingerprint;
  }

  // Invariant n°3 du plan : « zéro écriture — aucune table touchée, aucun
  // outbox alimenté ». C'est le seul des six invariants qu'aucun test ne
  // tenait : il était vrai par construction, donc invisible, donc cassable
  // sans bruit. Une sonde d'aide qui écrirait pousserait une inscription vers
  // le serveur sans que personne l'ait demandé.
  test('invariant — la sonde ne touche RIEN, nulle part', () async {
    await insertCurrentYear();
    await insertCohort(studentId: 'ancien');
    await insertEnrolled(studentId: 'deja', enrollmentId: 'deja-e');

    final before = await databaseFingerprint();
    final found = await probe();
    final after = await databaseFingerprint();

    // La sonde a bel et bien travaillé : sans ça, « rien n'a bougé » ne
    // prouverait rien du tout.
    expect(found, isNotEmpty);
    expect(after, before);
    // Nommé à part, parce que c'est celle qui parle au serveur.
    expect(await db.query(OutboxDao.table), isEmpty);
  });

  test('une année explicite court-circuite la résolution locale', () async {
    // Pas d'année courante en base, mais l'appelant en fournit une : les
    // dossiers de l'année remontent quand même.
    await insertEnrolled(studentId: 'deja', enrollmentId: 'deja-e');

    final found = await probe(academicYearId: year);

    expect([for (final c in found) c.studentId], ['deja']);
  });
}
