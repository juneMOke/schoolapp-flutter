// Le genre de l'élève sur un cas disciplinaire pullé.
//
// Le contrat (`DisciplinaryCaseDelta.studentGender`, enum MALE/FEMALE/OTHER)
// déclare le champ mais **hors `required`** : le front doit le reprendre quand
// le serveur le dit, et se replier sans jamais blanchir une valeur locale
// exacte quand il se tait. Un genre faux sur une fiche disciplinaire désigne
// une personne : il n'y a pas de « valeur par défaut acceptable » à afficher.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_pull_models.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

/// JSON minimal d'un cas au delta ; [gender] absent = clé non émise.
Map<String, dynamic> deltaJson({Object? gender = _absent}) => <String, dynamic>{
  'id': 'case-1',
  'studentId': 'stu-1',
  'studentFirstName': 'Amina',
  'studentLastName': 'Kalala',
  'academicYearId': 'ay-1',
  'category': 'FIGHTING',
  'severity': 'SERIOUS',
  'title': 'Incident',
  'content': 'Bagarre',
  'disciplinaryCaseDate': '2026-05-04',
  'status': 'OPEN',
  'sanction': 'DETENTION',
  'clientUpdatedAt': '2026-05-04T08:00:00.000Z',
  'serverUpdatedAt': '2026-05-04T08:00:05.000Z',
  if (gender != _absent) 'studentGender': gender,
};

const Object _absent = Object();

void main() {
  group('DisciplinaryCaseDeltaDto — genre au wire', () {
    test('le genre affirmé par le serveur est repris tel quel', () {
      final dto = DisciplinaryCaseDeltaDto.fromJson(
        deltaJson(gender: 'FEMALE'),
      );

      expect(dto.studentGender, 'FEMALE');
      expect(dto.toPulled(1000).caseRow.studentGender, 'FEMALE');
      expect(dto.toPulled(1000).serverStudentGender, 'FEMALE');
    });

    test('genre absent du delta : repli OTHER, serveur réputé muet', () {
      final dto = DisciplinaryCaseDeltaDto.fromJson(deltaJson());

      expect(dto.studentGender, isNull);
      // La colonne est NOT NULL : la ligne porte le repli…
      expect(dto.toPulled(1000).caseRow.studentGender, 'OTHER');
      // …mais rien n'est affirmé, donc rien ne sera réécrit en base.
      expect(dto.toPulled(1000).serverStudentGender, isNull);
    });

    test('genre nul explicite : traité comme un silence', () {
      final dto = DisciplinaryCaseDeltaDto.fromJson(deltaJson(gender: null));

      expect(dto.studentGender, isNull);
      expect(dto.toPulled(1000).caseRow.studentGender, 'OTHER');
    });

    test('genre hors enum : traité comme un silence, jamais stocké', () {
      final dto = DisciplinaryCaseDeltaDto.fromJson(deltaJson(gender: 'X'));

      expect(dto.studentGender, isNull);
      expect(dto.toPulled(1000).caseRow.studentGender, 'OTHER');
    });

    test('genre non textuel : la ligne n\'est pas empoisonnée', () {
      final dto = DisciplinaryCaseDeltaDto.fromJson(deltaJson(gender: 2));

      expect(dto.studentGender, isNull);
      expect(dto.toPulled(1000).caseRow.studentGender, 'OTHER');
    });

    test('la casse du wire est normalisée sur l\'enum du contrat', () {
      final dto = DisciplinaryCaseDeltaDto.fromJson(deltaJson(gender: 'male'));

      expect(dto.studentGender, 'MALE');
      expect(
        StudentGenderX.fromApiValue(dto.toPulled(1000).caseRow.studentGender),
        StudentGender.male,
      );
    });
  });

  group('applyPulledCases — genre en base', () {
    late Database db;
    late DisciplinaryLocalDataSource local;

    setUp(() async {
      db = await openFullOfflineDb();
      local = DisciplinaryLocalDataSource(db);
    });

    tearDown(() async => db.close());

    Future<void> seed({
      required String gender,
      required String syncStatus,
    }) async {
      await db.insert(
        DisciplinaryLocalDataSource.table,
        OfflineDisciplinaryCaseRow(
          id: 'case-1',
          studentId: 'stu-1',
          studentFirstName: 'Amina',
          studentLastName: 'Kalala',
          studentGender: gender,
          academicYearId: 'ay-1',
          disciplinaryCaseDate: '2026-05-04',
          title: 'Incident',
          content: 'Bagarre',
          updatedAt: 500,
          syncStatus: syncStatus,
        ).toMap(),
      );
    }

    Future<String?> storedGender() async =>
        (await local.getCase('case-1'))?.studentGender;

    Future<void> applyDelta({Object? gender = _absent}) =>
        local.applyPulledCases([
          DisciplinaryCaseDeltaDto.fromJson(
            deltaJson(gender: gender),
          ).toPulled(1000),
        ], 1000);

    test('cas inconnu : le genre serveur atterrit en base', () async {
      await applyDelta(gender: 'FEMALE');

      expect(await storedGender(), 'FEMALE');
    });

    test('cas inconnu sans genre au delta : repli OTHER en base', () async {
      await applyDelta();

      expect(await storedGender(), 'OTHER');
    });

    test(
      're-pull SYNCED : le genre serveur corrige le repli déjà en base',
      () async {
        await seed(gender: 'OTHER', syncStatus: SyncState.synced.dbValue);

        await applyDelta(gender: 'FEMALE');

        expect(await storedGender(), 'FEMALE');
      },
    );

    test('re-pull muet : le genre local exact n\'est pas blanchi', () async {
      await seed(gender: 'FEMALE', syncStatus: SyncState.synced.dbValue);

      await applyDelta();

      expect(await storedGender(), 'FEMALE');
    });

    test(
      're-pull hors enum : le genre local exact n\'est pas blanchi',
      () async {
        await seed(gender: 'FEMALE', syncStatus: SyncState.synced.dbValue);

        await applyDelta(gender: 'INCONNU');

        expect(await storedGender(), 'FEMALE');
      },
    );

    test(
      'écriture locale non synchronisée : son genre est intouchable',
      () async {
        await seed(gender: 'FEMALE', syncStatus: SyncState.pendingSync.dbValue);

        await applyDelta(gender: 'MALE');

        expect(await storedGender(), 'FEMALE');
      },
    );
  });
}
