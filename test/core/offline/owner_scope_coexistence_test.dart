import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/owner_scope.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_ref_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_row.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/offline/schedule_ref_local_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_recurring_session_row.dart';

import 'offline_full_test_db.dart';

/// Coexistence de DEUX comptes enseignants sur la MÊME tablette — le scénario
/// que la partition `owner_uid` existe pour couvrir (cf. `owner_scope.dart`).
///
/// Le choix produit ici est la coexistence, pas la purge au changement de
/// compte : sur une app offline-first, purger obligerait chaque prof à
/// retrouver du réseau après le passage de son collègue, alors que ses données
/// étaient déjà en base.
void main() {
  late Database db;
  late ScheduleRefLocalDataSource scheduleLocal;
  late AcademicsRefLocalDataSource academicsLocal;

  const profA = 'uid-prof-a';
  const profB = 'uid-prof-b';

  setUp(() async {
    db = await openFullOfflineDb();
    scheduleLocal = ScheduleRefLocalDataSource(db);
    academicsLocal = AcademicsRefLocalDataSource(db);
  });

  tearDown(() async => db.close());

  RefRecurringSessionRow session(String id, String coursId) =>
      RefRecurringSessionRow(
        id: id,
        academicYearId: 'ay-1',
        coursId: coursId,
        timeSlotId: 't1',
        dayOfWeek: 'MON',
        teacherId: 'teacher-x',
        classroomId: 'class-1',
        teacherLabel: 'M. X',
        classroomLabel: '3e A',
        subjectLabel: 'Maths',
        syncedAt: 1,
      );

  RefCoursRow cours(String id, String ligneBaremeId) => RefCoursRow(
    id: id,
    classroomId: 'class-1',
    ligneBaremeId: ligneBaremeId,
    syncedAt: 1,
  );

  GradesReferentialBundleDto bundle({required String brancheNom}) =>
      GradesReferentialBundleDto(
        branches: [BrancheDto(id: 'b1', nom: brancheNom)],
        ligneBaremes: const [
          LigneBaremeDto(
            id: 'lb1',
            grilleId: 'g1',
            rubriqueId: 'r1',
            brancheId: 'b1',
            ordre: 1,
            maxJournalierParSousPeriode: 10,
          ),
        ],
        chapitres: const [],
        periodes: const [],
        sousPeriodes: const [],
      );

  group('séances', () {
    test('chaque compte ne lit que les siennes', () async {
      await scheduleLocal.applyPulledSessions([
        session('s-a', 'co-a'),
      ], ownerUid: profA);
      await scheduleLocal.applyPulledSessions([
        session('s-b', 'co-b'),
      ], ownerUid: profB);

      final forA = await scheduleLocal.getSessionsForYear(
        'ay-1',
        ownerUid: profA,
      );
      final forB = await scheduleLocal.getSessionsForYear(
        'ay-1',
        ownerUid: profB,
      );

      expect(forA.map((s) => s.id), ['s-a']);
      expect(forB.map((s) => s.id), ['s-b']);
    });

    test('le pull du second compte n\'efface pas le cache du premier — c\'est '
        'tout l\'intérêt de la coexistence hors ligne', () async {
      await scheduleLocal.applyPulledSessions([
        session('s-a', 'co-a'),
      ], ownerUid: profA);
      await scheduleLocal.applyPulledSessions([
        session('s-b', 'co-b'),
      ], ownerUid: profB);

      expect(
        (await scheduleLocal.getAllSessions(ownerUid: profA)).single.id,
        's-a',
      );
    });
  });

  group('bundle grades-referential (références d\'école, ids partagés)', () {
    test('deux comptes portent la MÊME ligne de barème sans s\'écraser '
        '(clé primaire composite)', () async {
      await academicsLocal.replaceGradesReferential(
        bundle(brancheNom: 'Maths vues par A'),
        ownerUid: profA,
      );
      await academicsLocal.replaceGradesReferential(
        bundle(brancheNom: 'Maths vues par B'),
        ownerUid: profB,
      );

      expect(
        (await academicsLocal.getBranche('b1', ownerUid: profA))?.nom,
        'Maths vues par A',
      );
      expect(
        (await academicsLocal.getBranche('b1', ownerUid: profB))?.nom,
        'Maths vues par B',
      );
    });

    test('le remplacement d\'ensemble est borné au propriétaire : le pull de B '
        'ne vide pas le référentiel de A', () async {
      await academicsLocal.replaceGradesReferential(
        bundle(brancheNom: 'Maths'),
        ownerUid: profA,
      );

      // Bundle VIDE pour B (compte sans cours) : cas qui purgeait tout avant.
      await academicsLocal.replaceGradesReferential(
        const GradesReferentialBundleDto(
          branches: [],
          ligneBaremes: [],
          chapitres: [],
          periodes: [],
          sousPeriodes: [],
        ),
        ownerUid: profB,
      );

      expect(
        await academicsLocal.getLigneBareme('lb1', ownerUid: profA),
        isNotNull,
      );
      expect(
        await academicsLocal.getLigneBareme('lb1', ownerUid: profB),
        isNull,
      );
    });
  });

  group('cours', () {
    test('« Mes cours » joint à propriétaire constant : le cours de A ne se '
        'joint jamais au barème de B', () async {
      await academicsLocal.replaceGradesReferential(
        bundle(brancheNom: 'Maths de A'),
        ownerUid: profA,
      );
      await academicsLocal.replaceGradesReferential(
        bundle(brancheNom: 'Maths de B'),
        ownerUid: profB,
      );
      await academicsLocal.applyPulledCours([
        cours('co-a', 'lb1'),
      ], ownerUid: profA);
      await academicsLocal.applyPulledCours([
        cours('co-b', 'lb1'),
      ], ownerUid: profB);

      final rowsA = await academicsLocal.getMyCoursesJoined(ownerUid: profA);

      expect(rowsA, hasLength(1));
      expect(rowsA.single['cours_id'], 'co-a');
      expect(rowsA.single['branche_nom'], 'Maths de A');
    });

    test('l\'éviction DF-L d\'un bootstrap ne touche que les cours du compte '
        'qui vient de synchroniser', () async {
      await academicsLocal.applyPulledCours([
        cours('co-a', 'lb1'),
      ], ownerUid: profA);
      await academicsLocal.applyPulledCours([
        cours('co-b', 'lb1'),
      ], ownerUid: profB);

      // Bootstrap de B qui ne ramène plus 'co-b' (cours réaffecté).
      final evicted = await academicsLocal.evictCoursNotIn(
        const {},
        ownerUid: profB,
      );

      expect(evicted, ['co-b']);
      expect(
        (await academicsLocal.getAllCours(ownerUid: profA)).single.id,
        'co-a',
        reason: 'les cours de A survivent au bootstrap de B',
      );
    });
  });

  group('clés de curseur', () {
    test('scopedResource sépare les comptes et laisse les bases héritées '
        'intactes', () {
      expect(
        scopedResource('schedule_sessions', profA),
        isNot(scopedResource('schedule_sessions', profB)),
      );
      expect(scopedResource('schedule_sessions', null), 'schedule_sessions');
      expect(scopedResource('schedule_sessions', ''), 'schedule_sessions');
    });

    test(
      'la clé scopée reste couverte par le LIKE de purge des migrations',
      () {
        expect(
          scopedResource('schedule_sessions', profA),
          startsWith('schedule_sessions'),
        );
        expect(ownerKey(null), kUnscopedOwnerUid);
        expect(ownerKey(profA), profA);
      },
    );
  });
}
