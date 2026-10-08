import 'package:sqflite_common/sqlite_api.dart';

/// Ce que la désactivation d'un élève change dans les autres tables locales.
///
/// Logé dans le socle : les modules qui filtrent (inscriptions, classes,
/// recouvrement, boutique) lisent `enrollment_suspensions` sans dépendre du
/// module qui l'écrit.
abstract final class EnrollmentSuspensionSql {
  static const String table = 'enrollment_suspensions';
  static const String membersTable = 'ref_classroom_members';

  /// Prédicat « l'inscription [enrollmentIdExpr] n'a aucune période ouverte ».
  ///
  /// À poser dans le `WHERE` d'une liste de travail bâtie sur `enrollments` :
  /// `AND ${EnrollmentSuspensionSql.notSuspended('e.id')}`.
  static String notSuspended(String enrollmentIdExpr) =>
      'NOT EXISTS (SELECT 1 FROM $table es '
      'WHERE es.enrollment_id = $enrollmentIdExpr '
      'AND es.reactivated_at IS NULL)';

  /// Prédicat « l'élève [studentIdExpr] a une période ouverte sur l'année
  /// [yearIdExpr] », pour les listes bâties sur l'élève (créances).
  static String studentSuspended(String studentIdExpr, String yearIdExpr) =>
      'EXISTS (SELECT 1 FROM $table es '
      'WHERE es.student_id = $studentIdExpr '
      'AND es.academic_year_id = $yearIdExpr '
      'AND es.reactivated_at IS NULL)';

  /// Projette la désactivation sur le membre de classe de chacun des
  /// [studentIds] : `INACTIVE` tant qu'une période est ouverte sur l'année du
  /// membre, `ACTIVE` sinon.
  ///
  /// Sans condition : à appeler après un geste, un accusé ou un refus, quand la
  /// table locale dit la vérité de l'élève. `INACTIVE` ne sert qu'à la
  /// suspension (une seule appartenance par élève et par année), d'où le
  /// retour sûr à `ACTIVE`. Un élève sans classe n'a rien à projeter.
  static Future<void> project(
    DatabaseExecutor db,
    Iterable<String> studentIds,
  ) => _project(db, studentIds, onlyWithPeriods: false);

  /// Même projection, restreinte aux élèves qui ont au moins une période sur
  /// l'année du membre.
  ///
  /// À appeler après une page du flux des membres : le pull remplace la ligne
  /// entière et effacerait un `INACTIVE` posé hors ligne avant l'envoi du
  /// geste. Un élève sans période garde le statut tiré du serveur.
  static Future<void> reapplyAfterMemberPull(
    DatabaseExecutor db,
    Iterable<String> studentIds,
  ) => _project(db, studentIds, onlyWithPeriods: true);

  static Future<void> _project(
    DatabaseExecutor db,
    Iterable<String> studentIds, {
    required bool onlyWithPeriods,
  }) async {
    final ids = studentIds.toSet().toList(growable: false);
    if (ids.isEmpty) return;
    const m = membersTable;
    for (var start = 0; start < ids.length; start += _chunk) {
      final chunk = ids.sublist(
        start,
        start + _chunk > ids.length ? ids.length : start + _chunk,
      );
      final marks = List.filled(chunk.length, '?').join(', ');
      await db.rawUpdate(
        'UPDATE $m SET status = CASE WHEN '
        '${studentSuspended('$m.student_id', '$m.academic_year_id')} '
        "THEN 'INACTIVE' ELSE 'ACTIVE' END "
        'WHERE $m.student_id IN ($marks)'
        '${onlyWithPeriods ? ' AND EXISTS (SELECT 1 FROM $table ep '
                  'WHERE ep.student_id = $m.student_id '
                  'AND ep.academic_year_id = $m.academic_year_id)' : ''}',
        chunk,
      );
    }
  }

  /// Sous la limite de variables liées de SQLite (999).
  static const int _chunk = 500;
}
