import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_row.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspended_member.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lectures des périodes de désactivation, scopées par école et par année.
class EnrollmentSuspensionReadDao {
  final DatabaseExecutor _db;

  const EnrollmentSuspensionReadDao(this._db);

  static const String table = EnrollmentSuspensionRow.table;

  /// Les périodes ouvertes de l'année, par inscription.
  Future<Map<String, StudentSuspension>> openByEnrollment({
    required String schoolId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      table,
      where:
          'school_id = ? AND academic_year_id = ? AND reactivated_at IS NULL',
      whereArgs: [schoolId, academicYearId],
    );
    return {
      for (final row in rows.map(EnrollmentSuspensionRow.new))
        row.enrollmentId: row.toEntity(),
    };
  }

  /// Nombre d'élèves désactivés sur l'année.
  Future<int> countOpen({
    required String schoolId,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM $table '
      'WHERE school_id = ? AND academic_year_id = ? AND reactivated_at IS NULL',
      [schoolId, academicYearId],
    );
    return (rows.single['n'] as int?) ?? 0;
  }

  /// La période qui dit l'état de l'inscription : l'ouverte s'il y en a une,
  /// sinon la dernière fermée ; `null` si l'élève n'a jamais été désactivé.
  Future<StudentSuspension?> latestFor(String enrollmentId) async {
    final rows = await _db.query(
      table,
      where: 'enrollment_id = ?',
      whereArgs: [enrollmentId],
      orderBy: '(reactivated_at IS NULL) DESC, suspended_at DESC',
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : EnrollmentSuspensionRow(rows.single).toEntity();
  }

  /// Les élèves désactivés de l'année qui ont une classe, avec elle.
  Future<List<SuspendedMember>> suspendedMembers({
    required String schoolId,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT es.*, m.classroom_id AS member_classroom_id, '
      'm.student_first_name AS member_first_name, '
      'm.student_last_name AS member_last_name, '
      'm.student_middle_name AS member_middle_name '
      'FROM $table es '
      'JOIN ref_classroom_members m '
      'ON m.student_id = es.student_id '
      'AND m.academic_year_id = es.academic_year_id '
      'WHERE es.school_id = ? AND es.academic_year_id = ? '
      'AND es.reactivated_at IS NULL '
      'ORDER BY m.student_last_name, m.student_first_name',
      [schoolId, academicYearId],
    );
    return [
      for (final r in rows)
        SuspendedMember(
          suspension: EnrollmentSuspensionRow(r).toEntity(),
          classroomId: r['member_classroom_id']! as String,
          lastName: r['member_last_name']! as String,
          middleName: r['member_middle_name'] as String?,
          firstName: r['member_first_name']! as String,
        ),
    ];
  }

  /// L'inscription complétée de l'élève sur l'année, si la tablette la tient.
  Future<String?> completedEnrollmentOf({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      'enrollments',
      columns: ['id'],
      where: "student_id = ? AND academic_year_id = ? AND status = 'COMPLETED'",
      whereArgs: [studentId, academicYearId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['id'] as String?;
  }
}
