import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../level_correction_fixtures.dart';

void main() {
  late Database db;
  late LevelCorrectionWriteDao writer;
  late LevelCorrectionSyncDao sync;
  late LevelCorrectionReadDao reader;

  setUp(() async {
    db = await openFullOfflineDb();
    writer = LevelCorrectionWriteDao(db);
    sync = LevelCorrectionSyncDao(db);
    reader = LevelCorrectionReadDao(db);
  });
  tearDown(() => db.close());

  Future<LevelCorrectionRecordOutcome> record(
    String id, {
    String enrollmentId = kEnrollment,
    String correctedAt = '2026-11-06T10:15:00.000Z',
  }) => writer.record(
    LevelCorrectionGesture(
      id: id,
      enrollmentId: enrollmentId,
      studentId: kStudent,
      academicYearId: kYear,
      fromSchoolLevelId: 'lvl-m2',
      toSchoolLevelId: 'lvl-p2',
      toSchoolLevelGroupId: 'grp-primaire',
      toClassroomId: 'cls-p2a',
      reason: 'Erreur de saisie au guichet',
      correctedAt: correctedAt,
      authorId: kAuthor,
    ),
    schoolId: kSchool,
    nowMs: 10,
  );

  group('LevelCorrectionWriteDao', () {
    test("la ligne et son entrée d'outbox s'écrivent ensemble", () async {
      expect(await record('g-1'), LevelCorrectionRecordOutcome.recorded);

      final entry = await OutboxDao(
        db,
      ).byId(LevelCorrectionWriteDao.entryId('g-1'));
      expect(entry, isNotNull);
      expect(entry!.aggregateType, 'ENROLLMENT_LEVEL_CORRECTION');
      expect(entry.aggregateId, kEnrollment);
      expect(entry.operation, OutboxOperation.create);
      expect(entry.schoolId, kSchool);
      expect(
        LevelCorrectionGesture.tryParse(jsonDecode(entry.payload)),
        correctionGesture('g-1'),
      );

      final latest = await reader.latestFor(kEnrollment);
      expect(latest?.status, LevelCorrectionStatus.pending);
      expect(latest?.toSchoolLevelId, 'lvl-p2');
    });

    test('une seconde correction de la même inscription en attente est '
        'refusée, sans rien écrire', () async {
      await record('g-1');
      expect(await record('g-2'), LevelCorrectionRecordOutcome.alreadyPending);
      expect(
        await OutboxDao(db).byId(LevelCorrectionWriteDao.entryId('g-2')),
        isNull,
      );
      expect((await reader.latestFor(kEnrollment))?.id, 'g-1');
    });

    test("une autre inscription n'est pas gênée", () async {
      await record('g-1');
      expect(
        await record('g-2', enrollmentId: 'enr-2'),
        LevelCorrectionRecordOutcome.recorded,
      );
    });

    test('une fois la première jugée, une nouvelle correction passe', () async {
      await record('g-1');
      await sync.markRefused(
        'g-1',
        code: 'STALE_LEVEL',
        reason: 'x',
        nowMs: 11,
      );
      expect(await record('g-2'), LevelCorrectionRecordOutcome.recorded);
    });

    test(
      'accusée mais pas encore descendue : une nouvelle correction attend',
      () async {
        await record('g-1');
        await sync.markApplied('g-1', nowMs: 20);
        expect(
          await record('g-2'),
          LevelCorrectionRecordOutcome.alreadyPending,
        );
        await sync.markSettled(pulledFromMs: 30, nowMs: 31);
        expect(
          await record('g-2', correctedAt: '2026-11-06T11:00:00.000Z'),
          LevelCorrectionRecordOutcome.recorded,
        );
      },
    );

    test("envoi abandonné par la file : la correction n'est plus « en "
        'attente », une nouvelle la remplace', () async {
      await record('g-1');
      await OutboxDao(
        db,
      ).markSyncError(LevelCorrectionWriteDao.entryId('g-1'), 'poison');
      expect(
        (await reader.latestFor(kEnrollment))?.status,
        LevelCorrectionStatus.stalled,
      );

      expect(
        await record('g-2', correctedAt: '2026-11-06T11:00:00.000Z'),
        LevelCorrectionRecordOutcome.recorded,
      );
      expect((await reader.latestFor(kEnrollment))?.id, 'g-2');
      // La première est close : relancée depuis la file, elle ne partira pas.
      expect(await sync.holds('g-1'), isFalse);
      final closed = await db.query(
        'enrollment_level_corrections',
        where: 'id = ?',
        whereArgs: ['g-1'],
      );
      expect(
        closed.single['sync_error_code'],
        LevelCorrectionWriteDao.supersededCode,
      );
    });

    test(
      'envoi abandonné puis relancé depuis la file : de nouveau en attente',
      () async {
        await record('g-1');
        final outbox = OutboxDao(db);
        final entryId = LevelCorrectionWriteDao.entryId('g-1');
        await outbox.markSyncError(entryId, 'poison');
        await outbox.requeue(entryId);
        expect(
          (await reader.latestFor(kEnrollment))?.status,
          LevelCorrectionStatus.pending,
        );
      },
    );

    test(
      'un versement sur l\'année : refus local, rien n\'est écrit',
      () async {
        await insertPayment(db, id: 'pay-1');
        expect(await record('g-1'), LevelCorrectionRecordOutcome.hasPayments);
        expect(await reader.latestFor(kEnrollment), isNull);
        expect(
          await OutboxDao(db).byId(LevelCorrectionWriteDao.entryId('g-1')),
          isNull,
        );
      },
    );

    test('un versement annulé retient aussi : le serveur le compte', () async {
      await insertPayment(db, id: 'pay-1', cancelledAt: 5);
      expect(await record('g-1'), LevelCorrectionRecordOutcome.hasPayments);
    });

    test('un versement d\'une autre année ne retient pas', () async {
      await insertPayment(db, id: 'pay-2', academicYearId: 'year-0');
      expect(await record('g-1'), LevelCorrectionRecordOutcome.recorded);
    });
  });

  group('LevelCorrectionSyncDao', () {
    test("un geste en attente est tenu ; jugé, il ne l'est plus", () async {
      await record('g-1');
      expect(await sync.holds('g-1'), isTrue);
      await sync.markApplied('g-1', nowMs: 20);
      expect(await sync.holds('g-1'), isFalse);
      expect(await sync.holds('absent'), isFalse);
    });

    test('accusé : la correction passe à « appliquée »', () async {
      await record('g-1');
      await sync.markApplied('g-1', nowMs: 20);
      final latest = await reader.latestFor(kEnrollment);
      expect(latest?.status, LevelCorrectionStatus.applied);
      expect(latest?.refusalCode, isNull);
      expect(await sync.hasUnsettled(), isTrue);
    });

    test("descente partie après l'accusé : « descendue », inscriptions "
        'renvoyées', () async {
      await record('g-1');
      await sync.markApplied('g-1', nowMs: 20);
      expect(await sync.markSettled(pulledFromMs: 20, nowMs: 40), {
        kEnrollment,
      });
      expect(
        (await reader.latestFor(kEnrollment))?.status,
        LevelCorrectionStatus.settled,
      );
      expect(await sync.hasUnsettled(), isFalse);
    });

    test("descente partie avant l'accusé : rien n'est descendu", () async {
      await record('g-1');
      await sync.markApplied('g-1', nowMs: 20);
      expect(await sync.markSettled(pulledFromMs: 19, nowMs: 40), isEmpty);
      expect(
        (await reader.latestFor(kEnrollment))?.status,
        LevelCorrectionStatus.applied,
      );
    });

    test('refus : le code reste sur la ligne', () async {
      await record('g-1');
      await sync.markRefused(
        'g-1',
        code: 'LEVEL_CORRECTION_HAS_PAYMENTS',
        reason: 'LEVEL_CORRECTION_HAS_PAYMENTS',
        nowMs: 20,
      );
      final latest = await reader.latestFor(kEnrollment);
      expect(latest?.status, LevelCorrectionStatus.refused);
      expect(latest?.refusalCode, 'LEVEL_CORRECTION_HAS_PAYMENTS');
    });

    test("disparition : la ligne s'efface", () async {
      await record('g-1');
      await sync.drop('g-1');
      expect(await reader.latestFor(kEnrollment), isNull);
    });
  });

  test('la dernière correction est la plus récemment posée', () async {
    await record('g-1');
    await sync.markRefused('g-1', code: 'STALE_LEVEL', reason: 'x', nowMs: 11);
    await record('g-2', correctedAt: '2026-11-06T11:00:00.000Z');
    expect((await reader.latestFor(kEnrollment))?.id, 'g-2');
  });

  group('garde du guichet (D7)', () {
    Future<bool> held({String academicYearId = kYear}) => reader
        .holdsCollection(studentId: kStudent, academicYearId: academicYearId);

    setUp(() => insertEnrollment(db, schoolLevelId: 'lvl-m2'));

    test('aucune correction : la caisse est ouverte', () async {
      expect(await held(), isFalse);
    });

    test('une correction en attente retient la caisse', () async {
      await record('g-1');
      expect(await held(), isTrue);
    });

    test("seulement pour l'année de la correction", () async {
      await record('g-1');
      expect(await held(academicYearId: 'year-0'), isFalse);
    });

    test(
      "en attente, mais l'entrée d'outbox est morte : la caisse rouvre",
      () async {
        await record('g-1');
        await OutboxDao(
          db,
        ).markSyncError(LevelCorrectionWriteDao.entryId('g-1'), 'illisible');
        expect(await held(), isFalse);
      },
    );

    test('refusée : la caisse rouvre', () async {
      await record('g-1');
      await sync.markRefused('g-1', code: 'STALE_LEVEL', reason: 'x', nowMs: 1);
      expect(await held(), isFalse);
    });

    test('accusée, nouvelle grille pas encore descendue : retenue', () async {
      await record('g-1');
      await sync.markApplied('g-1', nowMs: 1000);
      expect(await held(), isTrue);
    });

    test("accusée, l'inscription locale porte déjà la cible mais les créances "
        'ne sont pas descendues : toujours retenue', () async {
      await record('g-1');
      await sync.markApplied('g-1', nowMs: 1000);
      await db.update(
        'enrollments',
        {'school_level_id': 'lvl-p2'},
        where: 'id = ?',
        whereArgs: [kEnrollment],
      );
      expect(await held(), isTrue);
    });

    test('accusée puis descendue : la caisse rouvre', () async {
      await record('g-1');
      await sync.markApplied('g-1', nowMs: 1000);
      await sync.markSettled(pulledFromMs: 1000, nowMs: 2000);
      expect(await held(), isFalse);
    });

    test('seule la dernière correction compte', () async {
      await record('g-1');
      await OutboxDao(
        db,
      ).markSyncError(LevelCorrectionWriteDao.entryId('g-1'), 'poison');
      await record('g-2', correctedAt: '2026-11-06T11:00:00.000Z');
      expect(await held(), isTrue);
      await sync.markRefused('g-2', code: 'STALE_LEVEL', reason: 'x', nowMs: 1);
      expect(await held(), isFalse);
    });
  });
}
