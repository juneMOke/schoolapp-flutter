import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_reason.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../suspension_fixtures.dart';

void main() {
  late Database db;
  late EnrollmentSuspensionWriteDao writer;
  late EnrollmentSuspensionReadDao reader;

  setUp(() async {
    db = await openFullOfflineDb();
    writer = EnrollmentSuspensionWriteDao(db);
    reader = EnrollmentSuspensionReadDao(db);
    await insertMember(db, 's1');
    await insertMember(db, 's2');
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> outboxPayload(String gestureId) async {
    final entry = await OutboxDao(
      db,
    ).byId(EnrollmentSuspensionWriteDao.entryId(gestureId));
    return jsonDecode(entry!.payload) as Map<String, Object?>;
  }

  group('désactiver', () {
    test('un lot ouvre une période, une entrée d\'outbox et projette le '
        'membre par élève', () async {
      final applied = await writer.suspend(
        [
          suspendGesture('s1', reason: SuspensionReason.medical),
          suspendGesture('s2', precision: 'retour après les congés'),
        ],
        schoolId: kSchool,
        nowMs: 1,
      );

      expect(applied, {enrollmentOf('s1'), enrollmentOf('s2')});
      expect(await memberStatus(db, 's1'), 'INACTIVE');
      expect(await memberStatus(db, 's2'), 'INACTIVE');
      final open = await reader.openByEnrollment(
        schoolId: kSchool,
        academicYearId: kYear,
      );
      expect(open[enrollmentOf('s1')]!.reason, SuspensionReason.medical);
      expect(open[enrollmentOf('s1')]!.syncState, RecordSyncState.pending);
      expect(await outboxPayload('sus-s2'), containsPair('op', 'SUSPEND'));
      expect(
        await outboxPayload('sus-s2'),
        containsPair('precision', 'retour après les congés'),
      );
    });

    test('une inscription déjà désactivée est ignorée', () async {
      await writer.suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);
      final applied = await writer.suspend(
        [suspendGesture('s1', id: 'autre')],
        schoolId: kSchool,
        nowMs: 2,
      );

      expect(applied, isEmpty);
      expect(await OutboxDao(db).byId('ENROLLMENT_SUSPENSION:autre'), isNull);
      expect(
        await reader.countOpen(schoolId: kSchool, academicYearId: kYear),
        1,
      );
    });

    test('un élève sans classe se désactive sans projection', () async {
      final applied = await writer.suspend(
        [suspendGesture('sans-classe')],
        schoolId: kSchool,
        nowMs: 1,
      );
      expect(applied, {enrollmentOf('sans-classe')});
    });

    test('tout ou rien : une erreur au milieu du lot n\'écrit rien', () async {
      // Deux gestes au même id : la seconde insertion viole la clé primaire.
      final lot = [
        suspendGesture('s1', id: 'dup'),
        suspendGesture('s2', id: 'dup'),
      ];
      await expectLater(
        writer.suspend(lot, schoolId: kSchool, nowMs: 1),
        throwsA(isA<DatabaseException>()),
      );

      expect(
        await reader.countOpen(schoolId: kSchool, academicYearId: kYear),
        0,
      );
      expect(await OutboxDao(db).pendingCount(), 0);
      expect(await memberStatus(db, 's1'), 'ACTIVE');
    });
  });

  group('réactiver', () {
    test('ferme la période ouverte et rend le membre actif', () async {
      await writer.suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);
      final applied = await writer.reactivate(
        [reactivateGesture('s1')],
        schoolId: kSchool,
        nowMs: 2,
      );

      expect(applied, {enrollmentOf('s1')});
      expect(await memberStatus(db, 's1'), 'ACTIVE');
      final latest = await reader.latestFor(enrollmentOf('s1'));
      expect(latest!.isOpen, isFalse);
      expect(latest.id, 'sus-s1');
      final entry = await OutboxDao(db).byId('ENROLLMENT_SUSPENSION:rea-s1');
      expect(entry!.aggregateId, enrollmentOf('s1'));
      expect(entry.operation, OutboxOperation.update);
    });

    test('sans période ouverte, le geste est ignoré', () async {
      final applied = await writer.reactivate(
        [reactivateGesture('s1')],
        schoolId: kSchool,
        nowMs: 1,
      );
      expect(applied, isEmpty);
      expect(await OutboxDao(db).pendingCount(), 0);
    });

    test('une nouvelle désactivation ouvre une seconde période', () async {
      await writer.suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);
      await writer.reactivate(
        [reactivateGesture('s1')],
        schoolId: kSchool,
        nowMs: 2,
      );
      await writer.suspend(
        [suspendGesture('s1', id: 'sus-2', at: '2026-10-10T08:00:00.000Z')],
        schoolId: kSchool,
        nowMs: 3,
      );

      expect((await reader.latestFor(enrollmentOf('s1')))!.id, 'sus-2');
      expect(await memberStatus(db, 's1'), 'INACTIVE');
    });
  });
}
