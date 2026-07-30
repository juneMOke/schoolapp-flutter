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

/// Expression SQL normalisant un numéro de téléphone pour comparaison
/// (espaces/tirets/parenthèses retirés) — [expr] peut être un nom de colonne
/// ou un placeholder `?`. N'affecte jamais la valeur stockée, uniquement la
/// comparaison au moment de la requête.
String _normalizedPhoneSql(String expr) =>
    "REPLACE(REPLACE(REPLACE(REPLACE($expr, ' ', ''), '-', ''), '(', ''), ')', '')";

/// Draft d'un tuteur à confirmer : le modèle (id provisoire) + le lien de parenté.
class ParentDraft {
  final ParentLocalModel parent;
  final String relationshipType; // valeur API SCREAMING_SNAKE

  /// true si ce tuteur référence une fiche `parents` RÉELLE déjà en base
  /// (choisie via "Rechercher un parent") — pilote `upsertDraftGuardianParent`
  /// (défaut false : chemin historique RE/PRE via `upsertParentByPhone`,
  /// inchangé).
  final bool linkedToExisting;

  const ParentDraft({
    required this.parent,
    required this.relationshipType,
    this.linkedToExisting = false,
  });
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

/// Levée par [upsertDraftGuardianParent] quand le téléphone appartient déjà
/// à un AUTRE parent local (id différent).
class ParentPhoneConflictException implements Exception {
  final String phoneNumber;
  final String existingParentId;
  const ParentPhoneConflictException(this.phoneNumber, this.existingParentId);
}

/// Upsert d'un tuteur de l'étape Tuteurs — id fixé par l'UI, jamais généré
/// ici. Distinct de [upsertParentByPhone] (dédup fratrie RE/PRE, INCHANGÉ) :
/// - [linkedToExisting] = true ET la fiche existe encore : elle n'est PAS
///   réécrite, l'id est renvoyé tel quel ;
/// - [linkedToExisting] = true MAIS la fiche a disparu entre la sélection
///   (popin de recherche) et cette écriture (ex. remap/suppression par
///   `EnrollmentAckDao` si un ACK réseau concurrent est arrivé entretemps —
///   `student_parent` n'a aucune contrainte FOREIGN KEY, un lien vers un id
///   disparu serait donc ignoré SILENCIEUSEMENT à la lecture, faisant
///   disparaître le tuteur sans erreur) : on retombe sur le chemin normal
///   ci-dessous, qui RECRÉE la fiche avec les données déjà capturées côté UI
///   plutôt que de perdre le rattachement ;
/// - sinon (nouvelle saisie, jamais liée) : vérifie qu'AUCUN AUTRE parent
///   (id différent) ne porte déjà ce téléphone (throw
///   [ParentPhoneConflictException] sinon), puis upsert PAR ID (update si la
///   ligne existe déjà — re-sauvegarde de la même ligne UI —, sinon insert
///   neuve).
Future<String> upsertDraftGuardianParent(
  DatabaseExecutor txn,
  ParentLocalModel p, {
  required bool linkedToExisting,
  required bool asDraft,
}) async {
  if (linkedToExisting) {
    final linkedRow = await txn.query(
      'parents',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [p.id],
      limit: 1,
    );
    if (linkedRow.isNotEmpty) return p.id;
    // Fiche disparue : ne PAS renvoyer un id fantôme, tomber dans le chemin
    // normal (conflit + upsert) pour la recréer.
  }

  // Comparaison normalisée (espaces/tirets/parenthèses ignorés) : un même
  // numéro saisi "+243 111 222 333" puis "+243111222333" ne doit pas
  // échapper à la garde d'unicité pour une simple différence de mise en
  // forme. La valeur STOCKÉE n'est jamais modifiée, seule la comparaison
  // l'est — s'applique aussi aux lignes historiques déjà en base.
  final conflict = await txn.rawQuery(
    'SELECT id FROM parents WHERE ${_normalizedPhoneSql('phone_number')} = '
    '${_normalizedPhoneSql('?')} AND id != ? LIMIT 1',
    [p.phoneNumber, p.id],
  );
  if (conflict.isNotEmpty) {
    throw ParentPhoneConflictException(
      p.phoneNumber,
      conflict.first['id'] as String,
    );
  }

  final existing = await txn.query(
    'parents',
    columns: ['id'],
    where: 'id = ?',
    whereArgs: [p.id],
    limit: 1,
  );
  if (existing.isNotEmpty) {
    await txn.update(
      'parents',
      {
        'first_name': p.firstName,
        'last_name': p.lastName,
        'surname': p.surname,
        'phone_number': p.phoneNumber,
        'email': p.email,
        'updated_at': p.updatedAt,
      },
      where: 'id = ?',
      whereArgs: [p.id],
    );
    return p.id;
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
  String? authorId,
}) async {
  final command = EnrollmentCommand(
    enrollment: enrollmentPayloadOf(enrollment),
    student: studentPayloadOf(student),
    parents: parents,
    emitDocument: emitDocument,
    authorId: authorId,
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
