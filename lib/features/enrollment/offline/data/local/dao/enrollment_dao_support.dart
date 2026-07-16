import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

/// Primitives partagées par l'écriture Inscription (wizard draft/finalize M1) :
/// résolution des tuteurs, projection des payloads et
/// mise en file de l'agrégat outbox. Regroupées ici pour éviter la duplication
/// dans `EnrollmentDraftDao` (confirmation one-shot retirée à l'étape c).

/// Draft d'un tuteur à confirmer : le modèle (id provisoire) + le lien de parenté.
class ParentDraft {
  final ParentLocalModel parent;
  final String relationshipType; // valeur API SCREAMING_SNAKE

  const ParentDraft({required this.parent, required this.relationshipType});
}

/// Get-or-create local d'un parent par `phone_number` (dédup fratrie sur la
/// tablette). Renvoie l'id résolu (existant réutilisé, ou provisoire inséré).
///
/// [asDraft] : un parent NOUVEAU naît en `DRAFT` (au lieu du défaut
/// `PENDING_SYNC` du modèle) ; un parent existant n'a que ses champs rafraîchis
/// et n'est **jamais rétrogradé** (sync_status intact) quel que soit [asDraft].
Future<String> upsertParentByPhone(
  DatabaseExecutor txn,
  ParentLocalModel p, {
  required bool asDraft,
}) async {
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
  final map = p.toMap();
  if (asDraft) map['sync_status'] = SyncState.draft.dbValue;
  await txn.insert(
    'parents',
    map,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  return p.id;
}

/// Projette un `StudentLocalModel` en payload d'agrégat (pas de matricule/email
/// : générés serveur ; les null textuels sont normalisés en chaîne vide).
StudentPayload studentPayloadOf(StudentLocalModel s) => StudentPayload(
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

/// Projette un `EnrollmentLocalModel` en payload d'agrégat.
EnrollmentPayload enrollmentPayloadOf(EnrollmentLocalModel e) =>
    EnrollmentPayload(
      id: e.id,
      enrollmentType: e.enrollmentType,
      status: e.status,
      academicYearId: e.academicYearId,
      schoolLevelId: e.schoolLevelId,
      schoolLevelGroupId: e.schoolLevelGroupId,
      enrollmentDate: e.enrollmentDate,
      sourceRef: e.sourceRef,
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

/// Enfile **une** entrée outbox = l'agrégat inscription figé (student +
/// enrollment + parents). `aggregate_id = enrollment.id` (clé d'idempotence).
Future<void> enqueueEnrollmentAggregate(
  DatabaseExecutor txn, {
  required EnrollmentLocalModel enrollment,
  required StudentLocalModel student,
  required List<ParentPayload> parents,
  required bool emitDocument,
  required String outboxEntryId,
  required int nowMs,
  String? schoolId,
}) async {
  final command = EnrollmentCommand(
    enrollment: enrollmentPayloadOf(enrollment),
    student: studentPayloadOf(student),
    parents: parents,
    emitDocument: emitDocument,
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
}
