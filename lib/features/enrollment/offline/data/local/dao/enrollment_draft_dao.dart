import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

/// Écritures **DRAFT incrémentales** du wizard offline-first (M1) : chaque étape
/// persiste un brouillon local ; la finalisation bascule DRAFT → PENDING_SYNC et
/// enfile l'agrégat outbox.
class EnrollmentDraftDao {
  final Database _db;

  const EnrollmentDraftDao(this._db);

  /// Écrit la ligne élève de l'étape Identité en état **DRAFT** — sémantique
  /// **préservante** : si la ligne DRAFT existe déjà (ré-entrée sur l'étape, ou
  /// brouillon **seedé** RE/PRE), seules les colonnes d'identité sont mises à
  /// jour — jamais l'adresse ni un matricule déjà posé (le matricule n'est
  /// écrit que s'il est fourni). Sinon, insertion complète.
  Future<void> insertDraftStudent(StudentLocalModel student) async {
    await _db.transaction((txn) async {
      final existing = await txn.query(
        'students',
        columns: ['sync_status'],
        where: 'id = ?',
        whereArgs: [student.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        final map = student.toMap()..['sync_status'] = SyncState.draft.dbValue;
        await txn.insert('students', map);
        return;
      }
      await txn.update(
        'students',
        {
          'first_name': student.firstName,
          'last_name': student.lastName,
          'surname': student.surname,
          'gender': student.gender,
          'date_of_birth': student.dateOfBirth,
          'birth_place': student.birthPlace,
          'nationality': student.nationality,
          if (student.matriculationNumber != null)
            'matriculation_number': student.matriculationNumber,
          'updated_at': student.updatedAt,
        },
        where: 'id = ? AND sync_status = ?',
        whereArgs: [student.id, SyncState.draft.dbValue],
      );
    });
  }

  /// Écrit la ligne inscription de l'étape Identité en état **DRAFT** — même
  /// sémantique préservante : une ligne DRAFT existante (seed RE/PRE) ne voit
  /// mises à jour que les colonnes portées par l'étape ; `source_ref`, les
  /// antécédents et le niveau visé déjà saisis sont conservés (niveau/cycle ne
  /// sont écrits que s'ils sont fournis).
  /// Une chaîne blanche vaut « vide », pas « renseignée avec des espaces » —
  /// sans quoi la colonne porterait un texte qui se lirait comme une fiche
  /// remplie. Miroir de `normalizeToNull` côté serveur.
  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> insertDraftEnrollment(EnrollmentLocalModel enrollment) async {
    await _db.transaction((txn) async {
      final existing = await txn.query(
        'enrollments',
        columns: ['sync_status'],
        where: 'id = ?',
        whereArgs: [enrollment.id],
        limit: 1,
      );
      if (existing.isEmpty) {
        final map = enrollment.toMap()
          ..['sync_status'] = SyncState.draft.dbValue
          ..['medical_notes'] = _blankToNull(enrollment.medicalNotes);
        await txn.insert('enrollments', map);
        return;
      }
      await txn.update(
        'enrollments',
        {
          'student_id': enrollment.studentId,
          'enrollment_type': enrollment.enrollmentType,
          'status': enrollment.status,
          'academic_year_id': enrollment.academicYearId,
          'enrollment_date': enrollment.enrollmentDate,
          if (enrollment.schoolLevelId != null)
            'school_level_id': enrollment.schoolLevelId,
          if (enrollment.schoolLevelGroupId != null)
            'school_level_group_id': enrollment.schoolLevelGroupId,
          // **Omis = conservé, chaîne vide = vidé** — exactement la sémantique
          // du serveur sur ce champ, et pour la même raison : la fiche santé
          // peut avoir été seedée depuis le dossier N-1, et un appelant qui ne
          // la saisit pas (le seed lui-même, une correction d'identité venue
          // d'un chemin qui l'ignore) ne doit pas effacer des allergies sans
          // que personne ne l'ait demandé. La vider reste possible, mais il
          // faut le DIRE.
          if (enrollment.medicalNotes != null)
            'medical_notes': _blankToNull(enrollment.medicalNotes),
          'updated_at': enrollment.updatedAt,
        },
        where: 'id = ? AND sync_status = ?',
        whereArgs: [enrollment.id, SyncState.draft.dbValue],
      );
    });
  }

  /// Amorce un brouillon **complet** en une transaction (parcours RE/PRE : le
  /// dossier chargé du serveur, ou plus tard de `ref_previous_year_students` /
  /// `ref_pre_enrollments`, est photographié en local avant l'édition par
  /// étape). Ré-entrant : re-seeder rejoue la même photo serveur, les étapes
  /// éditent colonne-à-colonne par-dessus. Garde-fous :
  ///  - une ligne inscription de même id **déjà confirmée** (non-DRAFT) refuse
  ///    le seed (`false`) — on ne réouvre pas silencieusement un dossier parti
  ///    en synchro ;
  ///  - un élève existant **n'est jamais rétrogradé** (sync_status conservé,
  ///    identité rafraîchie) — même règle que les tuteurs (fratrie).
  Future<bool> seedDraft({
    required StudentLocalModel student,
    required EnrollmentLocalModel enrollment,
    required List<ParentDraft> parents,
    required int nowMs,
  }) async {
    return _db.transaction<bool>((txn) async {
      final existingEnrollment = await txn.query(
        'enrollments',
        columns: ['sync_status'],
        where: 'id = ?',
        whereArgs: [enrollment.id],
        limit: 1,
      );
      if (existingEnrollment.isNotEmpty &&
          existingEnrollment.first['sync_status'] != SyncState.draft.dbValue) {
        return false;
      }

      final existingStudent = await txn.query(
        'students',
        columns: ['sync_status'],
        where: 'id = ?',
        whereArgs: [student.id],
        limit: 1,
      );
      final studentStatus =
          existingStudent.isEmpty ||
              existingStudent.first['sync_status'] == SyncState.draft.dbValue
          ? SyncState.draft.dbValue
          : existingStudent.first['sync_status'];
      await txn.insert(
        'students',
        student.toMap()..['sync_status'] = studentStatus,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'enrollments',
        enrollment.toMap()..['sync_status'] = SyncState.draft.dbValue,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // RE/PRE : dédup fratrie silencieuse par téléphone (chemin historique,
      // délibérément non concerné par la garde d'unicité de l'étape Tuteurs).
      await _replaceParentsIn(
        txn,
        student.id,
        parents,
        enforcePhoneUniqueness: false,
      );
      return true;
    });
  }

  /// UPDATE **partiel colonne-à-colonne** d'un draft élève : n'écrit QUE les
  /// colonnes fournies (jamais un `toMap()` complet, qui écraserait à NULL les
  /// champs pas encore saisis). Gardé sur `sync_status = 'DRAFT'` pour ne jamais
  /// toucher un dossier déjà confirmé.
  Future<void> updateDraftStudentColumns(
    String studentId,
    Map<String, Object?> columns, {
    required int nowMs,
  }) async {
    if (columns.isEmpty) return;
    await _db.update(
      'students',
      {...columns, 'updated_at': nowMs},
      where: 'id = ? AND sync_status = ?',
      whereArgs: [studentId, SyncState.draft.dbValue],
    );
  }

  /// UPDATE partiel colonne-à-colonne d'un draft inscription (même garde-fou).
  Future<void> updateDraftEnrollmentColumns(
    String enrollmentId,
    Map<String, Object?> columns, {
    required int nowMs,
  }) async {
    if (columns.isEmpty) return;
    await _db.update(
      'enrollments',
      {...columns, 'updated_at': nowMs},
      where: 'id = ? AND sync_status = ?',
      whereArgs: [enrollmentId, SyncState.draft.dbValue],
    );
  }

  /// Remplace les tuteurs d'un draft (étape Tuteurs) : réétablit les liens
  /// `student_parent` de l'élève et upsert les parents. [enforcePhoneUniqueness]
  /// (true depuis l'étape Tuteurs interactive) bascule sur
  /// `upsertDraftGuardianParent` : téléphone en doublon avec un AUTRE parent
  /// → `ParentPhoneConflictException` (propage hors de la transaction,
  /// rollback automatique) ; tuteur explicitement lié via la recherche
  /// (`ParentDraft.linkedToExisting`) → fiche existante jamais réécrite.
  /// `false` (défaut, [seedDraft] RE/PRE) garde le comportement historique
  /// `upsertParentByPhone` (get-or-create par téléphone, dédup fratrie
  /// silencieuse). Un parent créé naît **DRAFT** ; un parent existant voit ses
  /// champs mis à jour mais **n'est jamais rétrogradé** en DRAFT.
  Future<void> replaceDraftParents(
    String studentId,
    List<ParentDraft> parents, {
    required int nowMs,
    bool enforcePhoneUniqueness = false,
  }) async {
    await _db.transaction(
      (txn) => _replaceParentsIn(
        txn,
        studentId,
        parents,
        enforcePhoneUniqueness: enforcePhoneUniqueness,
      ),
    );
  }

  /// Corps partagé du remplacement des tuteurs (étape Tuteurs et [seedDraft]).
  Future<void> _replaceParentsIn(
    DatabaseExecutor txn,
    String studentId,
    List<ParentDraft> parents, {
    required bool enforcePhoneUniqueness,
  }) async {
    // Au plus un désigné, vérifié AVANT d'écrire quoi que ce soit — pour la
    // raison détaillée sur [AmbiguousEmergencyContactException] : sous
    // `INSERT OR REPLACE`, l'index unique partiel ne refuserait pas la seconde
    // désignation, il ferait disparaître le lien de la première.
    final designatedCount = parents
        .where((draft) => draft.emergencyContact == true)
        .length;
    if (designatedCount > 1) {
      throw AmbiguousEmergencyContactException(studentId, designatedCount);
    }

    // **Lu AVANT la purge.** Ce remplacement efface tous les liens de l'élève
    // pour les réécrire : sans cette photo, un draft qui ne dit rien du contact
    // d'urgence (`null`) effacerait la désignation en place à chaque passage
    // sur l'étape Tuteurs. « Ne rien dire » doit valoir « ne touche à rien »
    // ici comme sur le fil.
    final previousDesignation = <String, bool>{
      for (final link in await txn.query(
        'student_parent',
        columns: const ['parent_id', 'emergency_contact'],
        where: 'student_id = ?',
        whereArgs: [studentId],
      ))
        link['parent_id'] as String:
            (link['emergency_contact'] as int? ?? 0) != 0,
    };

    await txn.delete(
      'student_parent',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    for (final draft in parents) {
      final resolvedId = enforcePhoneUniqueness
          ? await upsertDraftGuardianParent(
              txn,
              draft.parent,
              linkedToExisting: draft.linkedToExisting,
              asDraft: true,
            )
          : await upsertParentByPhone(txn, draft.parent, asDraft: true);
      final designated =
          draft.emergencyContact ?? previousDesignation[resolvedId] ?? false;
      await txn.insert('student_parent', {
        'student_id': studentId,
        'parent_id': resolvedId,
        'relationship_type': draft.relationshipType,
        'emergency_contact': designated ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Confirmation du draft (étape Résumé) : dans **une transaction**, bascule
  /// DRAFT → PENDING_SYNC sur l'élève, l'inscription et ses tuteurs DRAFT, crée
  /// le document provisoire si absent, et enfile **une** entrée outbox à **id
  /// déterministe** (`outbox-enr-<id>`) → un second appel remplace l'entrée
  /// (idempotent). No-op renvoyant `false` si l'inscription n'est plus en DRAFT
  /// (re-confirmation) ou introuvable ; `true` si la bascule a eu lieu.
  /// [finalStatus] non-null écrit aussi la colonne `status` (PRE → `COMPLETED`) ;
  /// `null` ne la touche pas (NEW/RE restent `IN_PROGRESS` en continu).
  Future<bool> finalizeDraft(
    String enrollmentId, {
    GeneratedDocumentLocalModel? document,
    bool emitDocument = true,
    String? schoolId,
    String? authorId,
    String? finalStatus,
    required int nowMs,
  }) async {
    return _db.transaction<bool>((txn) async {
      final eRows = await txn.query(
        'enrollments',
        where: 'id = ?',
        whereArgs: [enrollmentId],
        limit: 1,
      );
      if (eRows.isEmpty) return false;
      final enrollment = EnrollmentLocalModel.fromMap(eRows.first);
      if (enrollment.syncStatus != SyncState.draft.dbValue) return false;

      final sRows = await txn.query(
        'students',
        where: 'id = ?',
        whereArgs: [enrollment.studentId],
        limit: 1,
      );
      if (sRows.isEmpty) return false;
      final student = StudentLocalModel.fromMap(sRows.first);

      // Tuteurs liés : payload + bascule DRAFT → PENDING_SYNC.
      final linkRows = await txn.query(
        'student_parent',
        where: 'student_id = ?',
        whereArgs: [enrollment.studentId],
      );
      final parents = <ParentPayload>[];
      for (final link in linkRows) {
        final pRows = await txn.query(
          'parents',
          where: 'id = ?',
          whereArgs: [link['parent_id']],
          limit: 1,
        );
        if (pRows.isEmpty) continue;
        final parent = ParentLocalModel.fromMap(pRows.first);
        if (parent.syncStatus == SyncState.draft.dbValue) {
          await txn.update(
            'parents',
            {'sync_status': SyncState.pendingSync.dbValue},
            where: 'id = ?',
            whereArgs: [parent.id],
          );
        }
        parents.add(
          ParentPayload(
            clientId: parent.id,
            firstName: parent.firstName,
            lastName: parent.lastName,
            surname: parent.surname,
            phoneNumber: parent.phoneNumber,
            email: parent.email,
            relationshipType: (link['relationship_type'] as String?) ?? 'OTHER',
            // **La base est projetée telle quelle : `1 → true`, `0 → false`.**
            //
            // Elle ne distingue pas « jamais désigné » de « désignation
            // retirée » — les deux valent 0 — et une projection en `true` ou
            // rien perdait donc le retrait au dernier saut avant le fil : la
            // case décochée à l'écran, le lien local à 0, et le serveur qui
            // garde son désigné jusqu'à ce que le pull suivant le remette.
            //
            // Envoyer `false` ne risque pas d'écraser une désignation faite
            // ailleurs : l'agrégat porte la liste COMPLÈTE des tuteurs de
            // l'élève, c'est une image entière, pas une retouche partielle.
            // Le tri-état reste utile en amont — `ParentDraft.emergencyContact`
            // à `null` veut dire « cette étape n'en parle pas » et laisse la
            // valeur en base intacte — mais ici, la base a déjà tranché.
            emergencyContact: (link['emergency_contact'] as int? ?? 0) != 0,
          ),
        );
      }

      // Document provisoire si demandé et absent.
      if (emitDocument && document != null) {
        final docRows = await txn.query(
          'generated_documents',
          columns: ['id'],
          where: 'enrollment_id = ?',
          whereArgs: [enrollmentId],
          limit: 1,
        );
        if (docRows.isEmpty) {
          await txn.insert(
            'generated_documents',
            document.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      // Bascule élève + inscription.
      await txn.update(
        'students',
        {'sync_status': SyncState.pendingSync.dbValue, 'updated_at': nowMs},
        where: 'id = ?',
        whereArgs: [student.id],
      );
      await txn.update(
        'enrollments',
        {
          'sync_status': SyncState.pendingSync.dbValue,
          'updated_at': nowMs,
          'status': ?finalStatus,
        },
        where: 'id = ?',
        whereArgs: [enrollmentId],
      );

      // Outbox : le payload doit porter le statut POST-bascule (`finalStatus`
      // écrase `status` dans la ligne juste au-dessus) — `enrollment` a été lu
      // avant l'UPDATE et resterait périmé si on le poussait tel quel.
      final outboxEnrollment = finalStatus == null
          ? enrollment
          : EnrollmentLocalModel.fromMap({
              ...eRows.first,
              'status': finalStatus,
            });

      // Outbox : 1 agrégat = 1 entrée, id déterministe (idempotence re-confirm).
      await enqueueEnrollmentAggregate(
        txn,
        enrollment: outboxEnrollment,
        student: student,
        parents: parents,
        emitDocument: emitDocument,
        outboxEntryId: 'outbox-enr-$enrollmentId',
        schoolId: schoolId,
        authorId: authorId,
        nowMs: nowMs,
      );
      return true;
    });
  }
}
