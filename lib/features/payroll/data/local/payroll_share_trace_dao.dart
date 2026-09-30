import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// « Ouvert dans WhatsApp le … », « PDF téléchargé le … » — sur cette tablette
/// seulement, jamais poussé (A6).
class PayrollShareTraceDao {
  final DatabaseExecutor _db;

  const PayrollShareTraceDao(this._db);

  static const String table = 'payroll_share_traces';

  Future<void> record({
    required String schoolId,
    required String month,
    required String staffMemberId,
    required PayrollShareChannel channel,
    required String sharedAt,
  }) => _db.insert(table, {
    'school_id': schoolId,
    'month': month,
    'staff_member_id': staffMemberId,
    'channel': channel.wire,
    'shared_at': sharedAt,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Map<String, Map<PayrollShareChannel, String>>> forSchool(
    String schoolId,
  ) async {
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    final result = <String, Map<PayrollShareChannel, String>>{};
    for (final row in rows) {
      final channel = PayrollShareChannel.fromWire(row['channel'] as String?);
      if (channel == null) continue;
      final key = PayrollSnapshot.traceKey(
        row['month']! as String,
        row['staff_member_id']! as String,
      );
      (result[key] ??= {})[channel] = row['shared_at']! as String;
    }
    return result;
  }
}
