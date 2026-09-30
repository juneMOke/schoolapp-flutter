import 'package:school_app_flutter/features/payroll/domain/services/payroll_attendance_rule.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les années scolaires de l'école, lues du socle d'Inscription : la paie en
/// dérive seule qu'un mois est hors année (N3).
class PayrollCalendarDao {
  final DatabaseExecutor _db;

  const PayrollCalendarDao(this._db);

  Future<List<PayrollSchoolYear>> schoolYears(String schoolId) async {
    final rows = await _db.query(
      'ref_academic_years',
      columns: ['start_date', 'end_date'],
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    String? day(Object? value) =>
        value is String && value.length >= 10 ? value.substring(0, 10) : null;
    return [
      for (final row in rows)
        (start: day(row['start_date']), end: day(row['end_date'])),
    ];
  }
}
