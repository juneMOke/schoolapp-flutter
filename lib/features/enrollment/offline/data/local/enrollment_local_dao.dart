import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Draft d'un tuteur à confirmer : le modèle (id provisoire) + le lien de parenté.
class ParentDraft {
  final ParentLocalModel parent;
  final String relationshipType; // valeur API SCREAMING_SNAKE

  const ParentDraft({required this.parent, required this.relationshipType});
}

/// DAO local du module Inscription (sqflite). Sert toutes les lectures offline
/// (listes / détail / recherche) et matérialise la transaction de confirmation
/// (F3) ainsi que le remap à l'ACK (F4).
class EnrollmentLocalDao {
  final Database _db;

  const EnrollmentLocalDao(this._db);

  // ── Écriture : confirmation atomique (F3) ──────────────────────────────────

  /// Transaction de confirmation : upsert parents (dédup par phone), insert
  /// student(PENDING_SYNC, matricule NULL), liens, upsert enrollment, insert
  /// document provisoire, enqueue outbox(ENROLLMENT). Renvoie l'id d'inscription.
  Future<String> confirmEnrollment({
    required StudentLocalModel student,
    required EnrollmentLocalModel enrollment,
    required List<ParentDraft> parents,
    GeneratedDocumentLocalModel? document,
    required String outboxEntryId,
    String? schoolId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      // 1. Parents : get-or-create par téléphone (fratrie sur la tablette).
      final resolvedParents = <ParentPayload>[];
      for (final draft in parents) {
        final resolvedId = await _upsertParent(txn, draft.parent);
        await txn.insert('student_parent', {
          'student_id': student.id,
          'parent_id': resolvedId,
          'relationship_type': draft.relationshipType,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        resolvedParents.add(
          ParentPayload(
            clientId: resolvedId,
            firstName: draft.parent.firstName,
            lastName: draft.parent.lastName,
            surname: draft.parent.surname,
            phoneNumber: draft.parent.phoneNumber,
            email: draft.parent.email,
            relationshipType: draft.relationshipType,
          ),
        );
      }

      // 2. Élève (PENDING_SYNC, matricule NULL).
      await txn.insert(
        'students',
        student.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Inscription (uuid client, date terrain, PENDING_SYNC).
      await txn.insert(
        'enrollments',
        enrollment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 4. Document provisoire (PROV-…).
      if (document != null) {
        await txn.insert(
          'generated_documents',
          document.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 5. Outbox : 1 agrégat = 1 entrée (aggregate_id = enrollment.id).
      final command = EnrollmentCommand(
        enrollment: _enrollmentPayload(enrollment),
        student: _studentPayload(student),
        parents: resolvedParents,
        emitDocument: enrollment.emitDocument,
      );
      final entry = OutboxEntry(
        id: outboxEntryId,
        aggregateType: 'ENROLLMENT',
        aggregateId: enrollment.id,
        operation: OutboxOperation.create,
        payload: jsonEncode(command.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      );
      await OutboxDao(txn).enqueue(entry);
    });
    return enrollment.id;
  }

  /// Get-or-create local d'un parent par `phone_number`. Renvoie l'id résolu
  /// (existant réutilisé, ou provisoire inséré).
  Future<String> _upsertParent(DatabaseExecutor txn, ParentLocalModel p) async {
    final existing = await txn.query(
      'parents',
      columns: ['id'],
      where: 'phone_number = ?',
      whereArgs: [p.phoneNumber],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as String;
      await txn.update(
        'parents',
        {
          'first_name': p.firstName,
          'last_name': p.lastName,
          'surname': p.surname,
          'email': p.email,
          'updated_at': p.updatedAt,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }
    await txn.insert(
      'parents',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return p.id;
  }

  // ── ACK / remap (F4) ───────────────────────────────────────────────────────

  /// Applique un ACK dans une transaction : COMMITTED → remap (matricule/email,
  /// parent provisoire→canonique dans `parents` ET `student_parent`, document
  /// PROV→DEFINITIVE, sync_status=SYNCED) ; VALIDATION_ERROR → SYNC_ERROR.
  Future<void> applyEnrollmentAck(
    EnrollmentAck ack, {
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      if (!ack.isCommitted) {
        await txn.update(
          'enrollments',
          {
            'sync_status': SyncState.syncError.dbValue,
            'sync_error': ack.error?.message ?? 'Rejet de validation',
          },
          where: 'id = ?',
          whereArgs: [ack.clientEnrollmentId],
        );
        final rows = await txn.query(
          'enrollments',
          columns: ['student_id'],
          where: 'id = ?',
          whereArgs: [ack.clientEnrollmentId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          await txn.update(
            'students',
            {'sync_status': SyncState.syncError.dbValue},
            where: 'id = ?',
            whereArgs: [rows.first['student_id']],
          );
        }
        return;
      }

      // Élève : matricule + email + SYNCED.
      final rows = await txn.query(
        'enrollments',
        columns: ['student_id'],
        where: 'id = ?',
        whereArgs: [ack.clientEnrollmentId],
        limit: 1,
      );
      final studentId = rows.isNotEmpty
          ? rows.first['student_id'] as String
          : ack.student?.id;
      if (studentId != null) {
        await txn.update(
          'students',
          {
            if (ack.student?.matriculationNumber != null)
              'matriculation_number': ack.student!.matriculationNumber,
            if (ack.student?.email != null) 'email': ack.student!.email,
            'sync_status': SyncState.synced.dbValue,
            'synced_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [studentId],
        );
      }

      // Parents : remap provisoire → canonique dans parents ET student_parent.
      for (final p in ack.parents) {
        if (p.clientId == p.id) {
          await txn.update(
            'parents',
            {'sync_status': SyncState.synced.dbValue, 'synced_at': nowMs},
            where: 'id = ?',
            whereArgs: [p.id],
          );
          continue;
        }
        final canonicalExists = await txn.query(
          'parents',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [p.id],
          limit: 1,
        );
        if (canonicalExists.isNotEmpty) {
          // Le canonique existe déjà (fratrie déjà synchro) : on repointe le
          // lien et on supprime le provisoire.
          await txn.rawUpdate(
            'UPDATE OR REPLACE student_parent SET parent_id = ? '
            'WHERE parent_id = ?',
            [p.id, p.clientId],
          );
          await txn.delete('parents', where: 'id = ?', whereArgs: [p.clientId]);
        } else {
          await txn.update(
            'parents',
            {
              'id': p.id,
              'sync_status': SyncState.synced.dbValue,
              'synced_at': nowMs,
            },
            where: 'id = ?',
            whereArgs: [p.clientId],
          );
          await txn.rawUpdate(
            'UPDATE OR REPLACE student_parent SET parent_id = ? '
            'WHERE parent_id = ?',
            [p.id, p.clientId],
          );
        }
      }

      // Document : PROV-… → DEFINITIVE (+ verificationToken).
      if (ack.document != null) {
        await txn.update(
          'generated_documents',
          {
            'number': ack.document!.number,
            'status': 'DEFINITIVE',
            'verification_token': ack.document!.verificationToken,
          },
          where: 'enrollment_id = ? AND doc_domain = ?',
          whereArgs: [ack.clientEnrollmentId, 'ENROLLMENT'],
        );
      }

      // Inscription : SYNCED (+ code / statut serveur).
      await txn.update(
        'enrollments',
        {
          'sync_status': SyncState.synced.dbValue,
          'synced_at': nowMs,
          'sync_error': null,
          if (ack.enrollment?.enrollmentCode != null)
            'enrollment_code': ack.enrollment!.enrollmentCode,
          if (ack.enrollment?.status != null) 'status': ack.enrollment!.status,
        },
        where: 'id = ?',
        whereArgs: [ack.clientEnrollmentId],
      );
    });
  }

  // ── FIFO gate (pour Facturation) ───────────────────────────────────────────

  /// Vrai si l'élève n'a AUCUNE inscription locale non-synchronisée : soit
  /// aucune inscription locale (élève préexistant), soit toutes SYNCED. Sert de
  /// garde-fou FIFO au handler PAYMENT.
  Future<bool> isStudentEnrollmentSynced(String studentId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM enrollments '
      'WHERE student_id = ? AND sync_status != ?',
      [studentId, SyncState.synced.dbValue],
    );
    return ((rows.first['c'] as int?) ?? 0) == 0;
  }

  // ── Lectures (F3 : servies depuis sqflite) ─────────────────────────────────

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

  /// Liste des dossiers, optionnellement filtrée par statut métier.
  Future<List<LocalEnrollmentListItem>> getEnrollments({String? status}) async {
    final where = status == null ? '' : 'WHERE e.status = ?';
    final rows = await _db.rawQuery(
      '$_listSelect $where ORDER BY e.updated_at DESC, e.enrollment_date DESC',
      status == null ? const [] : [status],
    );
    return rows.map(_listItem).toList();
  }

  /// Recherche par nom (prénom/nom, insensible via LIKE).
  Future<List<LocalEnrollmentListItem>> searchByName(String query) async {
    final like = '%${query.trim()}%';
    final rows = await _db.rawQuery(
      '$_listSelect WHERE s.last_name LIKE ? OR s.first_name LIKE ? '
      'ORDER BY s.last_name ASC',
      [like, like],
    );
    return rows.map(_listItem).toList();
  }

  /// Recherche par date de naissance exacte (yyyy-MM-dd).
  Future<List<LocalEnrollmentListItem>> searchByDateOfBirth(String dob) async {
    final rows = await _db.rawQuery(
      '$_listSelect WHERE s.date_of_birth = ? ORDER BY s.last_name ASC',
      [dob],
    );
    return rows.map(_listItem).toList();
  }

  /// Recherche par info académique (année / niveau / groupe de niveau).
  Future<List<LocalEnrollmentListItem>> searchByAcademicInfo({
    String? academicYearId,
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
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

  // ── Helpers payload ────────────────────────────────────────────────────────

  StudentPayload _studentPayload(StudentLocalModel s) => StudentPayload(
    id: s.id,
    firstName: s.firstName,
    lastName: s.lastName,
    surname: s.surname ?? '',
    gender: s.gender,
    dateOfBirth: s.dateOfBirth,
    birthPlace: s.birthPlace ?? '',
    nationality: s.nationality ?? '',
    city: s.city,
    district: s.district,
    municipality: s.municipality,
    neighborhood: s.neighborhood,
    address: s.address,
  );

  EnrollmentPayload _enrollmentPayload(EnrollmentLocalModel e) =>
      EnrollmentPayload(
        id: e.id,
        enrollmentType: e.enrollmentType,
        status: e.status,
        academicYearId: e.academicYearId,
        schoolLevelId: e.schoolLevelId,
        schoolLevelGroupId: e.schoolLevelGroupId,
        enrollmentDate: e.enrollmentDate,
        previousSchoolName: e.previousSchoolName,
        previousAcademicYear: e.previousAcademicYear,
        previousSchoolLevelGroup: e.previousSchoolLevelGroup,
        previousSchoolLevel: e.previousSchoolLevel,
        previousRate: e.previousRate,
        previousRank: e.previousRank,
        validatedPreviousYear: e.validatedPreviousYear,
        transferReason: e.transferReason,
        cancellationReason: e.cancellationReason,
      );
}
