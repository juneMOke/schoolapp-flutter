import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/database/phone_number_sql.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
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

  /// true si ce tuteur référence une fiche `parents` RÉELLE déjà en base
  /// (choisie via "Rechercher un parent") — pilote `upsertDraftGuardianParent`
  /// (défaut false : chemin historique RE/PRE via `upsertParentByPhone`,
  /// inchangé).
  final bool linkedToExisting;

  /// Désignation « contact d'urgence » **telle que l'écran la dit** : `true`
  /// désigne, `false` retire, `null` ne dit rien — et « ne rien dire » n'est
  /// pas « non ». Le remplacement des tuteurs efface puis réécrit tous les
  /// liens de l'élève ; sans ce troisième état, chaque passage sur l'étape
  /// Tuteurs effacerait une désignation posée ailleurs (cf.
  /// `_replaceParentsIn`).
  final bool? emergencyContact;

  const ParentDraft({
    required this.parent,
    required this.relationshipType,
    this.linkedToExisting = false,
    this.emergencyContact,
  });
}

/// Id du tuteur portant [rawPhone], quelle que soit l'écriture du numéro en
/// base — `null` si aucun.
///
/// Deux temps, parce qu'aucun des deux ne suffit seul : SQL pré-filtre sur
/// les derniers chiffres (tolérant aux séparateurs et à l'indicatif), Dart
/// tranche sur la forme canonique (qui, elle, distingue `+242…` de `+243…`).
/// Un numéro vide ne rapproche jamais : deux tuteurs sans téléphone ne sont
/// pas la même personne.
Future<String?> findParentIdByPhone(
  DatabaseExecutor txn,
  String rawPhone, {
  String? excludedId,
  String? whereSuffix,
  List<Object?> suffixArgs = const [],
}) async {
  final key = PhoneNumberSql.matchKeyOf(rawPhone);
  if (key.isEmpty) return null;

  final rows = await txn.rawQuery(
    'SELECT id, phone_number FROM parents WHERE '
    '${whereSuffix == null ? '' : '$whereSuffix AND '}'
    '${PhoneNumberSql.matchKey('phone_number')} = ?'
    '${excludedId == null ? '' : ' AND id != ?'} LIMIT 10',
    [...suffixArgs, key, ?excludedId],
  );

  for (final row in rows) {
    final candidate = (row['phone_number'] as String?) ?? '';
    if (PhoneNumberFormat.sameNumber(candidate, rawPhone)) {
      return row['id'] as String;
    }
  }
  return null;
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
  // Rapprochement insensible au format d'écriture : une fiche héritée
  // ("0816939060") et la saisie du jour ("+243816939060") désignent le même
  // tuteur, sans quoi la dédup fratrie créerait un doublon.
  final existingId = await findParentIdByPhone(txn, p.phoneNumber);
  if (existingId != null) {
    final id = existingId;
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

/// Deux tuteurs désignés contact d'urgence pour le même élève.
///
/// Levée **avant toute écriture**, et non laissée à l'index unique partiel :
/// les liens `student_parent` s'écrivent en `INSERT OR REPLACE` (clé composée
/// élève+tuteur), et sous ce mode SQLite **supprime la ligne en conflit** au
/// lieu de refuser. Le filet deviendrait alors un destructeur silencieux — le
/// tuteur précédemment désigné disparaîtrait du dossier, pas seulement son
/// drapeau.
///
/// Miroir local du `422 AMBIGUOUS_EMERGENCY_CONTACT` du serveur, et même
/// doctrine : ce n'est pas un conflit entre deux postes mais une contradiction
/// interne à une seule saisie. Rien à arbitrer, rien à rejouer — l'écran doit
/// la corriger.
class AmbiguousEmergencyContactException implements Exception {
  final String studentId;
  final int designatedCount;
  const AmbiguousEmergencyContactException(
    this.studentId,
    this.designatedCount,
  );

  @override
  String toString() =>
      'AmbiguousEmergencyContactException(student: $studentId, '
      'désignés: $designatedCount)';
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

  // Comparaison normalisée (indicatif, 0 du plan national et séparateurs
  // ignorés) : un même numéro saisi "+243 111 222 333", "0111222333" puis
  // "+243111222333" ne doit pas échapper à la garde d'unicité pour une
  // simple différence de mise en forme. La valeur STOCKÉE n'est jamais
  // modifiée, seule la comparaison l'est — s'applique aussi aux lignes
  // historiques déjà en base.
  final conflictId = await findParentIdByPhone(
    txn,
    p.phoneNumber,
    excludedId: p.id,
  );
  if (conflictId != null) {
    throw ParentPhoneConflictException(p.phoneNumber, conflictId);
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
///
/// [reductionCodes] vient d'une table à part (`enrollment_reductions`) et non
/// de la ligne : il est donc passé, pas dérivé.
EnrollmentPayload enrollmentPayloadOf(
  EnrollmentLocalModel e, {
  List<String> reductionCodes = const [],
}) => EnrollmentPayload(
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
  formerStudent: e.formerStudent,
  medicalNotes: e.medicalNotes,
  transferReason: e.transferReason,
  cancellationReason: e.cancellationReason,
  reductionCodes: reductionCodes,
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
  // Les réductions déclarées au guichet (ADR-021 V1) sont FIGÉES ICI, dans la
  // même transaction que l'enfilage : la commande d'outbox est un instantané,
  // et une relecture au moment du push renverrait ce que l'écran affiche
  // aujourd'hui plutôt que ce que le guichet a déclaré ce jour-là.
  final reductionRows = await txn.query(
    'enrollment_reductions',
    columns: ['reduction_code'],
    where: 'enrollment_id = ?',
    whereArgs: [enrollment.id],
    orderBy: 'reduction_code',
  );

  final command = EnrollmentCommand(
    enrollment: enrollmentPayloadOf(
      enrollment,
      reductionCodes: [
        for (final row in reductionRows) row['reduction_code'] as String,
      ],
    ),
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
