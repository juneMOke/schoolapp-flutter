import 'package:sqflite_common/sqlite_api.dart';

/// Ce que la désactivation d'un élève change dans les autres tables locales.
///
/// Logé dans le socle : les modules qui filtrent (inscriptions, classes,
/// recouvrement, boutique) lisent `enrollment_suspensions` sans dépendre du
/// module qui l'écrit.
///
/// ⚠️ **`INACTIVE` n'est pas propre à la suspension.** Côté serveur, il dit
/// aussi « a quitté cette classe » : un transfert A→B laisse deux lignes membre
/// pour la même année, A `INACTIVE` et B `ACTIVE`. La projection ne touche donc
/// jamais que l'**appartenance courante** ([currentMemberId]), jamais les
/// lignes d'historique.
abstract final class EnrollmentSuspensionSql {
  static const String table = 'enrollment_suspensions';
  static const String membersTable = 'ref_classroom_members';
  static const String transfersTable = 'classroom_transfers';

  /// Type d'agrégat des gestes de désactivation dans l'outbox.
  static const String aggregateType = 'ENROLLMENT_SUSPENSION';

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

  /// Sous-requête rendant l'id de l'appartenance courante de l'élève sur
  /// l'année : la classe de son dernier transfert s'il en a un, sinon sa ligne
  /// membre ; `ACTIVE` d'abord, puis la plus récente. Les deux expressions sont
  /// évaluées dans la portée de l'appelant.
  static String currentMemberId(String studentIdExpr, String yearIdExpr) =>
      '(SELECT cm.id FROM $membersTable cm '
      'WHERE cm.student_id = $studentIdExpr '
      'AND cm.academic_year_id = $yearIdExpr '
      'AND cm.classroom_id = COALESCE((SELECT t.to_classroom_id '
      'FROM $transfersTable t WHERE t.student_id = cm.student_id '
      'AND t.academic_year_id = cm.academic_year_id '
      'ORDER BY t.transferred_at DESC LIMIT 1), cm.classroom_id) '
      "ORDER BY (cm.status = 'ACTIVE') DESC, cm.updated_at DESC LIMIT 1)";

  /// Prédicat « le membre [alias] est la classe de l'élève » : `ACTIVE`, ou
  /// l'appartenance courante d'un élève désactivé — qui garde sa classe pour
  /// ses statistiques passées et ses pièces, sans revenir dans les listes de
  /// travail.
  static String activeOrSuspendedCurrent(String alias) =>
      "($alias.status = 'ACTIVE' OR ("
      '${studentSuspended('$alias.student_id', '$alias.academic_year_id')} '
      'AND $alias.id = '
      '${currentMemberId('$alias.student_id', '$alias.academic_year_id')}))';

  /// Projette sur l'appartenance courante de l'élève, pour chacune des
  /// [targets] `(élève, année)`, ce que dit la table locale : `INACTIVE` tant
  /// qu'une période est ouverte, `ACTIVE` sinon.
  ///
  /// À appeler après un geste local ou son refus. Un élève sans classe n'a
  /// rien à projeter ; une ligne d'historique n'est jamais touchée.
  static Future<void> project(
    DatabaseExecutor db,
    Iterable<(String studentId, String academicYearId)> targets,
  ) async {
    for (final (studentId, yearId) in targets.toSet()) {
      await db.rawUpdate(
        'UPDATE $membersTable SET status = CASE WHEN '
        '${studentSuspended('?', '?')} '
        "THEN 'INACTIVE' ELSE 'ACTIVE' END "
        'WHERE id = ${currentMemberId('?', '?')}',
        [studentId, yearId, studentId, yearId],
      );
    }
  }

  /// Après une page du flux des membres : le `REPLACE` vient de remettre le
  /// statut du serveur, qui ignore encore les gestes en file. Seuls les élèves
  /// de [studentIds] dont un geste attend sont reprojetés ; les autres gardent
  /// la vérité du serveur, qui projette lui-même ses périodes.
  static Future<void> reapplyAfterMemberPull(
    DatabaseExecutor db,
    Iterable<String> studentIds,
  ) async {
    final ids = studentIds.toSet().toList(growable: false);
    if (ids.isEmpty) return;
    for (var start = 0; start < ids.length; start += _chunk) {
      final chunk = ids.sublist(
        start,
        start + _chunk > ids.length ? ids.length : start + _chunk,
      );
      final marks = List.filled(chunk.length, '?').join(', ');
      // L'attente se lit dans l'outbox, pas sur la ligne : une entrée
      // empoisonnée par le moteur n'attend plus rien.
      final pending = await db.rawQuery(
        'SELECT DISTINCT es.student_id, es.academic_year_id FROM $table es '
        'JOIN outbox o ON o.aggregate_id = es.enrollment_id '
        "AND o.aggregate_type = '$aggregateType' AND o.status = 'PENDING' "
        'WHERE es.student_id IN ($marks)',
        chunk,
      );
      await project(db, [
        for (final r in pending)
          (r['student_id']! as String, r['academic_year_id']! as String),
      ]);
    }
  }

  /// Sous la limite de variables liées de SQLite (999).
  static const int _chunk = 500;
}
