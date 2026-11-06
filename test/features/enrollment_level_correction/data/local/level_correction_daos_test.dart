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

  Future<bool> record(String id, {String enrollmentId = kEnrollment}) =>
      writer.record(
        correctionGesture(id, enrollmentId: enrollmentId),
        schoolId: kSchool,
        nowMs: 10,
      );

  group('LevelCorrectionWriteDao', () {
    test("la ligne et son entrée d'outbox s'écrivent ensemble", () async {
      expect(await record('g-1'), isTrue);

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
      expect(await record('g-2'), isFalse);
      expect(
        await OutboxDao(db).byId(LevelCorrectionWriteDao.entryId('g-2')),
        isNull,
      );
      expect((await reader.latestFor(kEnrollment))?.id, 'g-1');
    });

    test('une autre inscription n\'est pas gênée', () async {
      await record('g-1');
      expect(await record('g-2', enrollmentId: 'enr-2'), isTrue);
    });

    test('une fois la première jugée, une nouvelle correction passe', () async {
      await record('g-1');
      await sync.markRefused(
        'g-1',
        code: 'STALE_LEVEL',
        reason: 'x',
        nowMs: 11,
      );
      expect(await record('g-2'), isTrue);
    });
  });

  group('LevelCorrectionSyncDao', () {
    test('un geste en attente est tenu ; jugé, il ne l\'est plus', () async {
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

    test('disparition : la ligne s\'efface', () async {
      await record('g-1');
      await sync.drop('g-1');
      expect(await reader.latestFor(kEnrollment), isNull);
    });
  });

  test('la dernière correction est la plus récemment jugée', () async {
    await record('g-1');
    await sync.markRefused('g-1', code: 'STALE_LEVEL', reason: 'x', nowMs: 11);
    await writer.record(correctionGesture('g-2'), schoolId: kSchool, nowMs: 30);
    expect((await reader.latestFor(kEnrollment))?.id, 'g-2');
  });
}
