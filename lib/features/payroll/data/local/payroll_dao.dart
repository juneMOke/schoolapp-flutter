import 'dart:convert';

import 'package:school_app_flutter/features/payroll/data/local/payroll_gesture_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_line_json.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_header.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les paies telles que le serveur les tient (`payrolls`, `payroll_lines`),
/// avec ce qu'elles portent : éléments variables et gestes enregistrés.
class PayrollDao {
  final PayrollStore _store;

  PayrollDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'payrolls';
  static const String linesTable = 'payroll_lines';

  /// Une page du flux. Rend le nombre de paies.
  Future<int> apply(
    List<PayrollDto> payrolls, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (payrolls.isEmpty || schoolId.isEmpty) return 0;
    await _store.transaction((txn) async {
      for (final payroll in payrolls) {
        await _applyOne(txn, payroll, schoolId: schoolId, nowMs: nowMs);
      }
    });
    return payrolls.length;
  }

  /// L'accusé d'un geste parti de [from]. Un accusé arrive parfois **après**
  /// un pull plus récent (un autre poste a déjà fait avancer la paie) : il ne
  /// doit pas la faire reculer. Il ne s'applique donc que si la paie est
  /// encore, sur la tablette, dans l'état d'où le geste est parti.
  Future<void> applyAck(
    PayrollDto payroll, {
    required String from,
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    final rows = await txn.query(
      table,
      columns: ['status'],
      where: 'school_id = ? AND month = ?',
      whereArgs: [schoolId, payroll.month],
    );
    if (rows.isNotEmpty && rows.single['status'] != from) {
      await PayrollGestureDao.applyServer(
        txn,
        payroll.month,
        payroll.gestures,
        schoolId: schoolId,
      );
      return;
    }
    await _applyOne(txn, payroll, schoolId: schoolId, nowMs: nowMs);
  });

  static Future<void> _applyOne(
    DatabaseExecutor txn,
    PayrollDto payroll, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (await _isOlder(txn, payroll, schoolId)) return;
    await txn.delete(
      table,
      where: 'school_id = ? AND month = ? AND id != ?',
      whereArgs: [schoolId, payroll.month, payroll.id],
    );
    await PayrollStore.upsert(
      txn,
      table,
      {'id': payroll.id},
      {
        'school_id': schoolId,
        'month': payroll.month,
        'status': payroll.status,
        'submitted_at': payroll.submittedAt,
        'submitted_by_name': payroll.submittedBy,
        'validated_at': payroll.validatedAt,
        'validated_by_name': payroll.validatedBy,
        'return_reason': payroll.returnReason,
        'validation_gesture_id': payroll.validationGestureId,
        'server_updated_at': payroll.serverUpdatedAt,
        'updated_at': nowMs,
      },
    );
    final validated = payroll.status == PayrollStatus.validated.wire;
    final lines = payroll.lines;
    // Hors validation, il n'y a rien de figé ; une paie validée garde ses
    // lignes tant qu'un accusé qui ne les porte pas ne les remplace pas.
    if (!validated || lines != null) {
      await txn.delete(
        linesTable,
        where: 'school_id = ? AND month = ?',
        whereArgs: [schoolId, payroll.month],
      );
    }
    // Une ligne illisible et tout le mois reste non figé : un livre figé à
    // N−1 agents perdrait des retenues d'avance, qui seraient reprises le
    // mois suivant.
    final parsed = [
      for (final line in lines ?? const <Map<dynamic, dynamic>>[])
        (line, PayrollLineJson.tryParse(line, month: payroll.month)),
    ];
    if (validated && lines != null && parsed.every((p) => p.$2 != null)) {
      for (final (raw, line) in parsed) {
        await txn.insert(linesTable, {
          'school_id': schoolId,
          'month': payroll.month,
          'staff_member_id': line!.staffMemberId,
          'currency': line.currency,
          'net_in_cents': line.netInCents,
          'line': jsonEncode(raw),
          'updated_at': nowMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await PayrollVariablesDao.applyServer(
      txn,
      payroll.month,
      payroll.variables,
      schoolId: schoolId,
      nowMs: nowMs,
    );
    await PayrollGestureDao.applyServer(
      txn,
      payroll.month,
      payroll.gestures,
      schoolId: schoolId,
    );
  }

  /// Une page qui porte une paie **plus ancienne** que celle de la tablette
  /// (rejeu, pages croisées) ne l'écrase pas.
  static Future<bool> _isOlder(
    DatabaseExecutor txn,
    PayrollDto payroll,
    String schoolId,
  ) async {
    final incoming = DateTime.tryParse(payroll.serverUpdatedAt ?? '');
    if (incoming == null) return false;
    final rows = await txn.query(
      table,
      columns: ['server_updated_at'],
      where: 'school_id = ? AND month = ?',
      whereArgs: [schoolId, payroll.month],
    );
    if (rows.isEmpty) return false;
    final current = DateTime.tryParse(
      rows.single['server_updated_at'] as String? ?? '',
    );
    return current != null && incoming.isBefore(current);
  }

  Future<Map<String, PayrollHeader>> headers(String schoolId) async {
    final rows = await _store.db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    return {
      for (final row in rows)
        if (PayrollStatus.fromWire(row['status'] as String?) case final status?)
          row['month']! as String: PayrollHeader(
            id: row['id']! as String,
            month: row['month']! as String,
            status: status,
            submittedAt: row['submitted_at'] as String?,
            submittedBy: row['submitted_by_name'] as String?,
            validatedAt: row['validated_at'] as String?,
            validatedBy: row['validated_by_name'] as String?,
            returnReason: row['return_reason'] as String?,
            validationGestureId: row['validation_gesture_id'] as String?,
          ),
    };
  }

  /// Mois → lignes figées.
  Future<Map<String, List<PayrollLine>>> frozenLines(String schoolId) async {
    final rows = await _store.db.query(
      linesTable,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'month ASC, staff_member_id ASC',
    );
    final result = <String, List<PayrollLine>>{};
    for (final row in rows) {
      final month = row['month']! as String;
      Object? raw;
      try {
        raw = jsonDecode(row['line']! as String);
      } catch (_) {
        continue;
      }
      final line = PayrollLineJson.tryParse(raw, month: month);
      if (line != null) (result[month] ??= []).add(line);
    }
    return result;
  }
}
