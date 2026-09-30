import 'dart:convert';

import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_fingerprint_json.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les gestes du circuit (`payroll_gestures`) : ceux de la tablette, avec
/// leur entrée d'outbox, et ceux que le serveur a enregistrés.
///
/// Une entrée **par geste**, jamais fusionnée : « rouvrir, corriger,
/// revalider » ne laisserait sinon partir que la validation.
class PayrollGestureDao {
  final PayrollStore _store;

  PayrollGestureDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'payroll_gestures';

  static String entryId(String gestureId) =>
      PayrollOutbox.entryId(PayrollOutbox.gesture, gestureId);

  Future<void> add(
    PayrollGestureRequestDto request, {
    required String schoolId,
    required int nowMs,
    String? authorName,
  }) => _store.transaction((txn) async {
    await txn.insert(table, {
      'id': request.gestureId,
      'school_id': schoolId,
      'month': request.month,
      'kind': request.kind,
      'reason': request.reason,
      'expected': request.expected == null
          ? null
          : jsonEncode(PayrollFingerprintJson.encode(request.expected!)),
      'recorded_at': request.clientRecordedAt,
      'author_name': authorName,
      'sync_status': StaffSyncState.pending.dbValue,
      'created_at': nowMs,
    });
    await PayrollStore.enqueue(
      txn,
      PayrollQueued(
        entryId: entryId(request.gestureId),
        aggregateType: PayrollOutbox.gesture,
        aggregateId: PayrollOutbox.monthKey(request.month),
        payload: request.toJson(),
      ),
      schoolId: schoolId,
      nowMs: nowMs,
    );
  });

  /// Les gestes que le serveur a enregistrés sur [month] : un geste de la
  /// tablette y figure dès qu'il est accusé, même si l'accusé s'est perdu.
  static Future<void> applyServer(
    DatabaseExecutor txn,
    String month,
    List<PayrollGestureDto> gestures, {
    required String schoolId,
  }) async {
    for (final gesture in gestures) {
      final updated = await txn.update(
        table,
        {
          'sync_status': StaffSyncState.synced.dbValue,
          'sync_error': null,
          'sync_error_code': null,
          'author_name': gesture.by,
        },
        where: 'id = ?',
        whereArgs: [gesture.gestureId],
      );
      if (updated > 0) continue;
      await txn.insert(table, {
        'id': gesture.gestureId,
        'school_id': schoolId,
        'month': month,
        'kind': gesture.kind,
        'reason': gesture.reason,
        'recorded_at': gesture.at,
        'author_name': gesture.by,
        'sync_status': StaffSyncState.synced.dbValue,
        'created_at':
            DateTime.tryParse(gesture.at)?.millisecondsSinceEpoch ?? 0,
      });
    }
  }

  Future<void> mark(
    String gestureId,
    StaffSyncState state, {
    String? code,
    String? reason,
    PayrollFingerprint? serverState,
  }) => _store.mark(
    table,
    {'id': gestureId},
    state,
    code: code,
    reason: reason,
    extra: {
      'server_state': serverState == null
          ? null
          : jsonEncode(PayrollFingerprintJson.encode(serverState)),
    },
  );

  /// Dans l'ordre de pose.
  Future<List<PayrollGesture>> forSchool(String schoolId) async {
    final rows = await _store.db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'created_at ASC, rowid ASC',
    );
    return [
      for (final row in rows)
        if (PayrollGestureKind.fromWire(row['kind'] as String?)
            case final kind?)
          PayrollGesture(
            id: row['id']! as String,
            month: row['month']! as String,
            kind: kind,
            reason: row['reason'] as String?,
            recordedAt: row['recorded_at']! as String,
            authorName: row['author_name'] as String?,
            expected: _fingerprint(row['expected']),
            serverState: _fingerprint(row['server_state']),
            syncState: StaffSyncState.fromDb(row['sync_status'] as String?),
            syncError: row['sync_error'] as String?,
            syncErrorCode: row['sync_error_code'] as String?,
          ),
    ];
  }

  static PayrollFingerprint? _fingerprint(Object? raw) {
    if (raw is! String) return null;
    try {
      return PayrollFingerprintJson.tryParse(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}
