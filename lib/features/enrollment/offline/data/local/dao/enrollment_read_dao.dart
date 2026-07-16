import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Lectures locales du module Inscription (F3 : servies depuis sqflite) :
/// listes / recherches / détail, plus le garde-fou FIFO `isStudentEnrollmentSynced`.
/// Les brouillons (`DRAFT`) du wizard offline **sont listés** (avec leur statut
/// métier, ex. `IN_PROGRESS`) pour être repris depuis le listing ; ils restent
/// exclus du PUSH tant qu'ils ne sont pas finalisés (`DRAFT → PENDING_SYNC`).
class EnrollmentReadDao {
  final Database _db;

  const EnrollmentReadDao(this._db);

  static const String _listSelect = '''
    SELECT e.id AS enrollment_id, e.student_id AS student_id,
           e.enrollment_type AS enrollment_type, e.status AS enrollment_status,
           e.enrollment_date AS enrollment_date,
           e.sync_status AS enrollment_sync_status,
           s.first_name AS first_name, s.last_name AS last_name,
           s.surname AS surname, s.date_of_birth AS date_of_birth,
           s.gender AS gender, s.matriculation_number AS matriculation_number
    FROM enrollments e
    JOIN students s ON s.id = e.student_id
  ''';

  LocalEnrollmentListItem _listItem(Map<String, Object?> r) =>
      LocalEnrollmentListItem(
        enrollmentId: r['enrollment_id'] as String,
        studentId: r['student_id'] as String,
        firstName: r['first_name'] as String,
        lastName: r['last_name'] as String,
        surname: r['surname'] as String?,
        dateOfBirth: r['date_of_birth'] as String,
        gender: OfflineGender.fromApiValue(r['gender'] as String?),
        enrollmentType: EnrollmentType.fromApiValue(
          r['enrollment_type'] as String?,
        ),
        status: OfflineEnrollmentStatus.fromApiValue(
          r['enrollment_status'] as String?,
        ),
        matriculationNumber: r['matriculation_number'] as String?,
        enrollmentDate: r['enrollment_date'] as String,
        syncState: SyncState.fromDbValue(
          r['enrollment_sync_status'] as String?,
        ),
      );

  /// Liste des dossiers, optionnellement filtrée par statut métier et/ou année
  /// scolaire. Le filtre `academicYearId` restaure la parité avec le listing
  /// online (scopé à l'année courante) : sans lui, des dossiers d'autres années
  /// de même statut se mélangeraient dès que le pull peuple plusieurs années.
  Future<List<LocalEnrollmentListItem>> getEnrollments({
    String? status,
    String? academicYearId,
    String? enrollmentType,
  }) async {
    // Les brouillons (DRAFT) remontent désormais dans les listes (repris depuis
    // le listing) : aucun filtre sur `sync_status`. Le scope reste le statut
    // métier (`status`) et l'année, comme le listing online. Filtre `type`
    // optionnel : la page Pré-inscriptions le fixe à `PRE_ENROLLMENT` pour ne
    // pas mélanger les dossiers de réinscription (même statut PRE_REGISTERED).
    final clauses = <String>[];
    final args = <Object?>[];
    if (status != null) {
      clauses.add('e.status = ?');
      args.add(status);
    }
    if (academicYearId != null) {
      clauses.add('e.academic_year_id = ?');
      args.add(academicYearId);
    }
    if (enrollmentType != null) {
      clauses.add('e.enrollment_type = ?');
      args.add(enrollmentType);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _db.rawQuery(
      '$_listSelect $where ORDER BY e.updated_at DESC, e.enrollment_date DESC',
      args,
    );
    return rows.map(_listItem).toList();
  }

  /// Recherche par info académique (année / niveau / groupe de niveau).
  Future<List<LocalEnrollmentListItem>> searchByAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
    // Brouillons inclus (repris depuis le listing) : aucun filtre `sync_status`.
    final clauses = <String>[];
    final args = <Object?>[];
    if (academicYearId != null) {
      clauses.add('e.academic_year_id = ?');
      args.add(academicYearId);
    }
    if (schoolLevelId != null) {
      clauses.add('e.school_level_id = ?');
      args.add(schoolLevelId);
    }
    if (schoolLevelGroupId != null) {
      clauses.add('e.school_level_group_id = ?');
      args.add(schoolLevelGroupId);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _db.rawQuery(
      '$_listSelect $where ORDER BY e.updated_at DESC',
      args,
    );
    return rows.map(_listItem).toList();
  }

  /// Référence (`id` + axe synchro) d'un dossier local **déjà existant** pour un
  /// élève sur une année donnée. `null` si aucun. Sert à la fois à la garde anti
  /// double-réinscription (présence) et à la **sonde au tap** RE (le `syncState`
  /// pilote reprise vs lecture seule). Scopé par l'année d'écriture (bootstrap,
  /// cf. seed RE) pour ne jamais confondre le dossier N-1.
  Future<LocalDossierRef?> findLocalDossierRefForStudentYear({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      'enrollments',
      columns: ['id', 'sync_status'],
      where: 'student_id = ? AND academic_year_id = ?',
      whereArgs: [studentId, academicYearId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return LocalDossierRef(
      enrollmentId: r['id'] as String,
      syncState: SyncState.fromDbValue(r['sync_status'] as String?),
    );
  }

  /// Détail complet d'un dossier (inscription + élève + tuteurs + documents).
  Future<LocalEnrollmentDetail?> getDetail(String enrollmentId) async {
    final eRows = await _db.query(
      'enrollments',
      where: 'id = ?',
      whereArgs: [enrollmentId],
      limit: 1,
    );
    if (eRows.isEmpty) return null;
    final enrollment = EnrollmentLocalModel.fromMap(eRows.first);

    final sRows = await _db.query(
      'students',
      where: 'id = ?',
      whereArgs: [enrollment.studentId],
      limit: 1,
    );
    if (sRows.isEmpty) return null;
    final student = StudentLocalModel.fromMap(sRows.first);

    final linkRows = await _db.query(
      'student_parent',
      where: 'student_id = ?',
      whereArgs: [enrollment.studentId],
    );
    final parents = <LocalParent>[];
    for (final link in linkRows) {
      final pRows = await _db.query(
        'parents',
        where: 'id = ?',
        whereArgs: [link['parent_id']],
        limit: 1,
      );
      if (pRows.isNotEmpty) {
        parents.add(
          ParentLocalModel.fromMap(pRows.first).toEntity(
            OfflineRelationshipType.fromApiValue(
              link['relationship_type'] as String?,
            ),
          ),
        );
      }
    }

    final docRows = await _db.query(
      'generated_documents',
      where: 'enrollment_id = ?',
      whereArgs: [enrollmentId],
    );
    final documents = docRows
        .map((r) => GeneratedDocumentLocalModel.fromMap(r).toEntity())
        .toList();

    return LocalEnrollmentDetail(
      enrollment: enrollment.toEntity(),
      student: student.toEntity(),
      parents: parents,
      documents: documents,
    );
  }

  /// Vrai si l'élève n'a AUCUNE inscription locale non-synchronisée : soit
  /// aucune inscription locale (élève préexistant), soit toutes SYNCED. Sert de
  /// garde-fou FIFO au handler PAYMENT (dépendance ENROLLMENT→PAYMENT).
  Future<bool> isStudentEnrollmentSynced(String studentId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM enrollments '
      'WHERE student_id = ? AND sync_status != ?',
      [studentId, SyncState.synced.dbValue],
    );
    return ((rows.first['c'] as int?) ?? 0) == 0;
  }
}
