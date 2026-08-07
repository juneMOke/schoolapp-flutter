import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Vérifie la migration v3→v4 (Présence : passage au modèle SESSION-agrégat).
///
/// On reproduit une base **pré-session** : `attendance_records` sans `session_id`
/// et sans table `attendance_sessions`, plus un `outbox` portant une entrée
/// `ATTENDANCE` au format full-write obsolète. La migration doit backfiller une
/// session rétroactive par appel legacy, rattacher les records et purger l'outbox.
const String _legacyAttendanceRecordsDdl = '''
  CREATE TABLE attendance_records (
    id TEXT PRIMARY KEY,
    student_id TEXT NOT NULL,
    student_first_name TEXT NOT NULL,
    student_last_name TEXT NOT NULL,
    student_middle_name TEXT,
    student_gender TEXT NOT NULL DEFAULT 'OTHER',
    classroom_id TEXT NOT NULL,
    attendance_date TEXT NOT NULL,
    academic_year_id TEXT NOT NULL,
    present INTEGER NOT NULL DEFAULT 1,
    absence_reason TEXT,
    absence_reason_note TEXT,
    version INTEGER,
    updated_at INTEGER NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
    synced_at INTEGER,
    UNIQUE (student_id, attendance_date, academic_year_id)
  )
''';

const String _outboxDdl = '''
  CREATE TABLE outbox (
    id TEXT PRIMARY KEY,
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    payload TEXT NOT NULL,
    school_id TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING',
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    next_attempt_at INTEGER NOT NULL DEFAULT 0,
    last_error TEXT
  )
''';

bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await db.execute(_legacyAttendanceRecordsDdl);
  await db.execute(_outboxDdl);
  return db;
}

Future<bool> _hasColumn(Database db, String table, String column) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.any((r) => r['name'] == column);
}

Map<String, Object?> _legacyRecord({
  required String id,
  required String studentId,
  required String classroomId,
  required String date,
  int updatedAt = 100,
}) => {
  'id': id,
  'student_id': studentId,
  'student_first_name': 'F$studentId',
  'student_last_name': 'L$studentId',
  'student_gender': 'OTHER',
  'classroom_id': classroomId,
  'attendance_date': date,
  'academic_year_id': 'ay-1',
  'present': 0,
  'absence_reason': 'SICKNESS',
  'updated_at': updatedAt,
  'sync_status': 'SYNCED',
};

void main() {
  test(
    'v3→v4 : backfill d\'une session par appel, records rattachés, outbox purgé',
    () async {
      final db = await _openLegacyDb();
      addTearDown(db.close);

      // Appel A (classe c1, 2026-05-04) : deux absents.
      await db.insert(
        'attendance_records',
        _legacyRecord(
          id: 'r1',
          studentId: 's1',
          classroomId: 'c1',
          date: '2026-05-04',
          updatedAt: 100,
        ),
      );
      await db.insert(
        'attendance_records',
        _legacyRecord(
          id: 'r2',
          studentId: 's2',
          classroomId: 'c1',
          date: '2026-05-04',
          updatedAt: 250,
        ),
      );
      // Appel B (classe c1, 2026-05-05) : un absent.
      await db.insert(
        'attendance_records',
        _legacyRecord(
          id: 'r3',
          studentId: 's1',
          classroomId: 'c1',
          date: '2026-05-05',
          updatedAt: 300,
        ),
      );
      // Appel C (classe c2, 2026-05-04) : un absent.
      await db.insert(
        'attendance_records',
        _legacyRecord(
          id: 'r4',
          studentId: 's9',
          classroomId: 'c2',
          date: '2026-05-04',
          updatedAt: 400,
        ),
      );

      // Outbox legacy au format full-write (à purger).
      await db.insert('outbox', {
        'id': 'ATTENDANCE:c1|2026-05-04|ay-1',
        'aggregate_type': 'ATTENDANCE',
        'aggregate_id': 'c1|2026-05-04|ay-1',
        'operation': 'UPSERT',
        'payload': '{"classroomId":"c1"}',
        'created_at': 100,
      });
      // Une entrée d'un autre agrégat ne doit PAS être purgée.
      await db.insert('outbox', {
        'id': 'PAYMENT:p1',
        'aggregate_type': 'PAYMENT',
        'aggregate_id': 'p1',
        'operation': 'CREATE',
        'payload': '{}',
        'created_at': 100,
      });

      expect(await _hasColumn(db, 'attendance_records', 'session_id'), isFalse);

      await migrateOfflineDatabase(db, 3, buildOfflineSchema());

      // Table session créée + colonne de lien ajoutée.
      expect(await _hasColumn(db, 'attendance_records', 'session_id'), isTrue);

      // Une session par (classe, date, année) distinct : 3 appels.
      final sessions = await db.query(
        'attendance_sessions',
        orderBy: 'attendance_date, classroom_id',
      );
      expect(sessions.length, 3);
      for (final s in sessions) {
        expect(s['sync_status'], 'SYNCED');
        expect(s['academic_year_id'], 'ay-1');
        expect(s['synced_at'], isNotNull);
        // uuid v4 forgé en SQL : 36 caractères, version 4.
        final id = s['id'] as String;
        expect(id.length, 36);
        expect(id[14], '4');
      }

      // `updated_at` de la session = max des records de l'appel (LWW).
      final sessionA = sessions.firstWhere(
        (s) =>
            s['classroom_id'] == 'c1' && s['attendance_date'] == '2026-05-04',
      );
      expect(sessionA['updated_at'], 250);

      // Chaque record rattaché à la session de sa clé naturelle.
      final records = await db.query('attendance_records', orderBy: 'id');
      for (final r in records) {
        expect(r['session_id'], isNotNull);
        final owning = sessions.firstWhere(
          (s) =>
              s['classroom_id'] == r['classroom_id'] &&
              s['attendance_date'] == r['attendance_date'] &&
              s['academic_year_id'] == r['academic_year_id'],
        );
        expect(r['session_id'], owning['id']);
      }

      // Outbox : l'entrée ATTENDANCE purgée, l'autre agrégat conservé.
      final outbox = await db.query('outbox');
      expect(outbox.length, 1);
      expect(outbox.single['aggregate_type'], 'PAYMENT');
    },
  );

  test('v3→v4 : idempotent si relancé (aucune session dupliquée)', () async {
    final db = await _openLegacyDb();
    addTearDown(db.close);

    await db.insert(
      'attendance_records',
      _legacyRecord(
        id: 'r1',
        studentId: 's1',
        classroomId: 'c1',
        date: '2026-05-04',
      ),
    );

    await migrateOfflineDatabase(db, 3, buildOfflineSchema());
    final firstSessionId = (await db.query('attendance_sessions')).single['id'];

    // Rejouer la migration (records déjà rattachés → GROUP BY sur session_id NULL vide).
    await migrateAttendanceToSessionModel(db, buildOfflineSchema());

    final sessions = await db.query('attendance_sessions');
    expect(sessions.length, 1);
    expect(sessions.single['id'], firstSessionId);
  });
}
