import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_notation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/cours_notation_detail_model.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notation_ref_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockCourseRemote extends Mock implements CourseRemoteDataSource {}

class MockDetailModel extends Mock implements CoursNotationDetailModel {}

CoursNotationDetail _detail({
  String coursId = 'co1',
  StatutPeriode periodeStatut = StatutPeriode.ouverte,
  StatutPeriode sousStatut = StatutPeriode.cloturee,
}) => CoursNotationDetail(
  coursId: coursId,
  classroomId: 'class-1',
  brancheNom: 'Maths',
  effectif: 30,
  periodes: [
    PeriodeNotation(
      periodeScolaireId: 'p1',
      ordre: 1,
      statut: periodeStatut,
      sousPeriodes: [
        SousPeriodeNotation(
          sousPeriodeId: 'sp1',
          ordre: 1,
          statut: sousStatut,
          nombreElevesNotes: 0,
          nombreEleves50: 0,
          moyennesEleves: const [],
          evaluationsParType: const [],
        ),
      ],
    ),
  ],
);

void main() {
  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('migration v8→v9', () {
    bool ffiInit = false;
    Future<Database> openV8() async {
      if (!ffiInit) {
        sqfliteFfiInit();
        ffiInit = true;
      }
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      // Pré-v9 : au moins l'outbox, pas de ref_cours_notation.
      await db.execute('CREATE TABLE outbox (id TEXT PRIMARY KEY)');
      return db;
    }

    test('crée ref_cours_notation, idempotent', () async {
      final db = await openV8();
      addTearDown(db.close);

      await migrateOfflineDatabase(db, 8, buildOfflineSchema());
      await migrateOfflineDatabase(db, 8, buildOfflineSchema());

      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        ['ref_cours_notation'],
      );
      expect(rows, isNotEmpty);
    });
  });

  group('RefCoursNotationRow.fromDetail (squelette)', () {
    test('sérialise l\'arbre période/sous-période + statut, round-trip', () {
      final row = RefCoursNotationRow.fromDetail(_detail(), syncedAt: 100);

      expect(row.coursId, 'co1');
      expect(row.effectif, 30);
      final periodes = row.periodes;
      expect(periodes.single.periodeScolaireId, 'p1');
      expect(periodes.single.statut, 'OUVERTE');
      expect(periodes.single.sousPeriodes.single.sousPeriodeId, 'sp1');
      expect(periodes.single.sousPeriodes.single.statut, 'CLOTUREE');
    });
  });

  group('NotationRefPullRepositoryImpl', () {
    late Database db;
    late AcademicsRefLocalDataSource refLocal;
    late MockCourseRemote remote;
    late NotationRefPullRepositoryImpl repo;

    setUp(() async {
      db = await openFullOfflineDb();
      refLocal = AcademicsRefLocalDataSource(db);
      remote = MockCourseRemote();
      repo = NotationRefPullRepositoryImpl(
        remoteDataSource: remote,
        refLocalDataSource: refLocal,
        requiredAuth: auth,
        now: () => 5000,
      );
    });
    tearDown(() async => db.close());

    Future<void> insertCours(String id) => db.insert('ref_cours', {
      'id': id,
      'classroom_id': 'class-1',
      'ligne_bareme_id': 'lb-1',
      'synced_at': 1,
    });

    test('met en cache le squelette de chaque cours local', () async {
      await insertCours('co1');
      final model = MockDetailModel();
      when(() => model.toEntity()).thenReturn(_detail());
      when(
        () => remote.getCoursNotationDetail(any(), 'co1'),
      ).thenAnswer((_) async => model);

      final result = await repo.syncNotationSkeletons();

      expect(result.isRight(), isTrue);
      final cached = await refLocal.getCoursNotation('co1');
      expect(cached, isNotNull);
      expect(cached!.effectif, 30);
      expect(cached.periodes.single.statut, 'OUVERTE');
    });

    test(
      'un cours en échec est sauté (best-effort), les autres passent',
      () async {
        await insertCours('co1');
        await insertCours('co2');
        when(
          () => remote.getCoursNotationDetail(any(), 'co1'),
        ).thenThrow(Exception('réseau'));
        final model = MockDetailModel();
        when(() => model.toEntity()).thenReturn(_detail(coursId: 'co2'));
        when(
          () => remote.getCoursNotationDetail(any(), 'co2'),
        ).thenAnswer((_) async => model);

        final result = await repo.syncNotationSkeletons();

        expect(result.isRight(), isTrue);
        expect(await refLocal.getCoursNotation('co1'), isNull);
        expect(await refLocal.getCoursNotation('co2'), isNotNull);
      },
    );

    test(
      'tous les cours en échec → Left (le coordinateur re-tentera)',
      () async {
        await insertCours('co1');
        when(
          () => remote.getCoursNotationDetail(any(), any()),
        ).thenThrow(Exception('hors-ligne'));

        final result = await repo.syncNotationSkeletons();

        expect(result.isLeft(), isTrue);
      },
    );
  });
}
