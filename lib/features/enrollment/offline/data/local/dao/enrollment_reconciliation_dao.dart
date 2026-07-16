import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ref_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';

/// Réconcilie la table `enrollments` (et `students`/`parents`/`student_parent`)
/// depuis les deux flux descendants du pull : le **delta maigre** (UPDATE-only,
/// réconciliation multi-tablettes) et les **snapshots hydratants** (UPSERT
/// write-preserving, reconstitution d'une tablette neuve). Écriture seule,
/// alimentée par `EnrollmentPullRepositoryImpl`.
class EnrollmentReconciliationDao {
  final Database _db;

  const EnrollmentReconciliationDao(this._db);

  /// Réconciliation descendante des `enrollments` (multi-tablettes).
  /// **UPDATE-only + LWW** :
  ///  - seules les lignes locales `SYNCED` sont touchées — jamais un brouillon
  ///    (`DRAFT`), une écriture en attente (`PENDING_SYNC`) ni un rejet à
  ///    arbitrer (`SYNC_ERROR`) ;
  ///  - LWW sur l'heure métier (`updated_at`, égalité comprise) : un delta plus
  ///    ancien que la ligne locale est ignoré. Limite assumée du LWW (comme en
  ///    Présence) : les heures métier proviennent d'horloges de tablettes
  ///    différentes — une horloge locale très en avance retarde la
  ///    réconciliation de SES dossiers jusqu'à rattrapage ;
  ///  - le niveau reçu réaligne le cycle via `ref_school_levels` (best-effort :
  ///    cycle conservé si le niveau manque au référentiel local) ; l'année
  ///    absente du delta conserve l'année locale ;
  ///  - le matricule du delta est répercuté sur l'élève (valeur canonique
  ///    serveur, ex. correction admin après l'ACK) ;
  ///  - les ids inconnus (dossier créé sur une autre tablette) sont ignorés en
  ///    V1 : le delta ne porte pas l'identité élève (NOT NULL locaux
  ///    intenables) — réconciliation complète différée (V1.1).
  /// Renvoie le nombre de lignes `enrollments` réellement modifiées.
  Future<int> applyEnrollmentDelta(
    List<EnrollmentDeltaDto> items, {
    required int syncedAt,
  }) async {
    var applied = 0;
    // Lots courts (verrou relâché entre les lots) : chaque UPDATE est
    // indépendant et idempotent → application partielle sûre (curseur non avancé
    // si un lot lève → rejeu).
    await applyInBatches(
      _db,
      items,
      apply: (txn, chunk) async {
        for (final d in chunk) {
          applied += await _applyDeltaItem(txn, d, syncedAt);
        }
      },
    );
    return applied;
  }

  /// Applique une ligne de delta dans [txn] (UPDATE-only + LWW, matricule
  /// canonique répercuté sur l'élève SYNCED). Renvoie le nombre de lignes
  /// `enrollments` modifiées (0 ou 1).
  Future<int> _applyDeltaItem(
    Transaction txn,
    EnrollmentDeltaDto d,
    int syncedAt,
  ) async {
    final updatedMs = isoToEpochMillis(d.updatedAt, fallback: syncedAt);
    final changed = await txn.rawUpdate(
      'UPDATE enrollments SET '
      'status = ?, '
      'school_level_id = COALESCE(?, school_level_id), '
      'school_level_group_id = CASE WHEN ? IS NULL '
      'THEN school_level_group_id '
      'ELSE COALESCE((SELECT level_group_id FROM ref_school_levels '
      'WHERE id = ?), school_level_group_id) END, '
      'academic_year_id = COALESCE(?, academic_year_id), '
      'updated_at = ?, '
      'synced_at = ? '
      'WHERE id = ? AND sync_status = ? AND updated_at <= ?',
      [
        d.status,
        d.schoolLevelId,
        d.schoolLevelId,
        d.schoolLevelId,
        d.academicYearId,
        updatedMs,
        syncedAt,
        d.id,
        SyncState.synced.dbValue,
        updatedMs,
      ],
    );
    if (changed > 0 && d.matriculationNumber != null) {
      // Valeur canonique serveur : appliquée seulement à un élève déjà SYNCED
      // (jamais écraser un brouillon RE réutilisant le `studentId`). Le garde
      // `!= null` évite déjà de nullifier un matricule posé.
      await txn.update(
        'students',
        {'matriculation_number': d.matriculationNumber},
        where: 'id = ? AND sync_status = ?',
        whereArgs: [d.studentId, SyncState.synced.dbValue],
      );
    }
    return changed;
  }

  /// Hydratation descendante des dossiers COMPLETS (`GET .../snapshots`).
  /// **UPSERT + write-preserving** — à l'inverse du delta maigre (UPDATE-only) :
  ///  - crée les lignes absentes (`enrollments`/`students`/`parents`) en `SYNCED`
  ///    → une tablette neuve reconstitue tous les dossiers ;
  ///  - ne touche JAMAIS une écriture locale non synchronisée : si la ligne
  ///    inscription OU élève existe déjà en DRAFT/PENDING_SYNC/SYNC_ERROR,
  ///    l'agrégat entier est ignoré (read-your-writes préservé, pas de
  ///    demi-écrasement ni de re-lien sur un brouillon) ;
  ///  - LWW sur `updated_at` (heure métier de l'agrégat, `updatedAt` ou à défaut
  ///    `serverUpdatedAt`) : un snapshot plus ancien qu'une ligne SYNCED locale
  ///    est ignoré (égalité comprise → rejeu idempotent) ;
  ///  - `source_ref`/`emit_document`/`sync_error` (hors contrat snapshot) sont
  ///    préservés — jamais de `ConflictAlgorithm.replace` sur ces 3 tables.
  /// Les documents (attestation) ne sont PAS portés par l'agrégat : un dossier
  /// hydraté n'a pas son PDF local (gap fonctionnel assumé en V1).
  /// Renvoie le nombre de dossiers `enrollments` réellement insérés/mis à jour.
  Future<int> upsertEnrollmentSnapshots(
    List<EnrollmentAggregateSnapshotDto> items, {
    required int syncedAt,
  }) async {
    var applied = 0;
    // Découpage en lots (cf. [applyInBatches]) : une transaction COURTE par lot
    // → le verrou de l'unique connexion sqflite est relâché entre les lots,
    // laissant les lectures UI (listing) s'intercaler au lieu d'attendre tout le
    // payload (~6-10 requêtes/dossier). Partiel sûr : upserts idempotents + LWW,
    // curseur non avancé si un lot lève → rejeu sans doublon.
    await applyInBatches(
      _db,
      items,
      apply: (txn, chunk) async {
        for (final agg in chunk) {
          if (await _applySnapshotAggregate(txn, agg, syncedAt)) applied++;
        }
      },
    );
    return applied;
  }

  /// Applique un agrégat snapshot dans [txn] (write-preserving + LWW). Renvoie
  /// `true` si l'inscription a été écrite (INSERT/UPDATE), `false` si l'agrégat
  /// a été sauté (écriture locale protégée) ou laissé intact (LWW).
  Future<bool> _applySnapshotAggregate(
    Transaction txn,
    EnrollmentAggregateSnapshotDto agg,
    int syncedAt,
  ) async {
    final e = agg.enrollment;
    final s = agg.student;
    final lwwMs = _snapshotLwwMillis(
      e.updatedAt,
      agg.serverUpdatedAt,
      fallback: syncedAt,
    );

    // Garde write-preserving : inscription OU élève local non synchronisé → on
    // saute tout l'agrégat (pas de demi-écriture ni de re-lien tuteur).
    if (await _isProtectedLocalWrite(txn, 'enrollments', e.id) ||
        await _isProtectedLocalWrite(txn, 'students', s.id)) {
      return false;
    }

    final studentUpdate = <String, Object?>{
      'first_name': s.firstName,
      'last_name': s.lastName,
      'surname': s.surname,
      'gender': s.gender,
      'date_of_birth': s.dateOfBirth,
      'birth_place': s.birthPlace,
      'nationality': s.nationality,
      'city': s.city,
      'district': s.district,
      'municipality': s.municipality,
      'neighborhood': s.neighborhood,
      'address': s.address,
      'phone_number': s.phoneNumber,
      'email': s.email,
    };
    // Matricule canonique : jamais nullifié (n'entre au SET que s'il est posé).
    if (s.matriculationNumber != null) {
      studentUpdate['matriculation_number'] = s.matriculationNumber;
    }
    await _upsertSnapshotRow(
      txn,
      table: 'students',
      id: s.id,
      lwwMs: lwwMs,
      syncedAt: syncedAt,
      insertValues: {
        'id': s.id,
        'first_name': s.firstName,
        'last_name': s.lastName,
        'surname': s.surname,
        'gender': s.gender,
        'date_of_birth': s.dateOfBirth,
        'birth_place': s.birthPlace,
        'nationality': s.nationality,
        'city': s.city,
        'district': s.district,
        'municipality': s.municipality,
        'neighborhood': s.neighborhood,
        'address': s.address,
        'phone_number': s.phoneNumber,
        'matriculation_number': s.matriculationNumber,
        'email': s.email,
      },
      updateValues: studentUpdate,
    );

    final enrollmentColumns = <String, Object?>{
      'student_id': e.studentId,
      'enrollment_type': e.enrollmentType,
      'status': e.status,
      'academic_year_id': e.academicYearId,
      'school_level_id': e.schoolLevelId,
      'school_level_group_id': e.schoolLevelGroupId,
      'enrollment_date': e.enrollmentDate,
      'enrollment_code': e.enrollmentCode,
      'previous_school_name': e.previousSchoolName,
      'previous_academic_year': e.previousAcademicYear,
      'previous_school_level_group': e.previousSchoolLevelGroup,
      'previous_school_level': e.previousSchoolLevel,
      'previous_rate': e.previousRate,
      'previous_rank': e.previousRank,
      'validated_previous_year': _boolToInt(e.validatedPreviousYear),
      'transfer_reason': e.transferReason,
      'cancellation_reason': e.cancellationReason,
    };
    final wroteEnrollment = await _upsertSnapshotRow(
      txn,
      table: 'enrollments',
      id: e.id,
      lwwMs: lwwMs,
      syncedAt: syncedAt,
      insertValues: {'id': e.id, ...enrollmentColumns},
      updateValues: enrollmentColumns,
    );

    final resolvedParentIds = <String>[
      for (final p in agg.parents)
        await _upsertSnapshotParent(txn, e.studentId, p, lwwMs, syncedAt),
    ];
    // L'agrégat porte l'ensemble COMPLET des tuteurs (contrat auto-suffisant) →
    // purge des liens vers des tuteurs SYNCED disparus du dossier serveur (les
    // liens vers un tuteur local protégé, non SYNCED, sont préservés).
    await _pruneStudentParentLinks(txn, e.studentId, resolvedParentIds);

    return wroteEnrollment;
  }

  /// Vrai si une ligne existe déjà à cet `id` avec un `sync_status` protégé
  /// (≠ SYNCED : DRAFT/PENDING_SYNC/SYNC_ERROR) — une écriture locale à ne
  /// jamais écraser par un pull descendant.
  Future<bool> _isProtectedLocalWrite(
    DatabaseExecutor txn,
    String table,
    String id,
  ) async {
    final rows = await txn.query(
      table,
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return (rows.first['sync_status'] as String?) != SyncState.synced.dbValue;
  }

  /// UPSERT gardé d'une ligne à `sync_status` (enrollments/students) depuis un
  /// snapshot descendant : INSERT si absente (en SYNCED), sinon UPDATE LWW
  /// réservé aux lignes SYNCED (une ligne SYNCED plus récente est laissée
  /// intacte). Renvoie `true` si la ligne a été écrite.
  Future<bool> _upsertSnapshotRow(
    DatabaseExecutor txn, {
    required String table,
    required String id,
    required int lwwMs,
    required int syncedAt,
    required Map<String, Object?> insertValues,
    required Map<String, Object?> updateValues,
  }) async {
    final existing = await txn.query(
      table,
      columns: ['sync_status', 'updated_at'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) {
      await txn.insert(table, {
        ...insertValues,
        'sync_status': SyncState.synced.dbValue,
        'synced_at': syncedAt,
        'updated_at': lwwMs,
      });
      return true;
    }
    final row = existing.first;
    final isSynced =
        (row['sync_status'] as String?) == SyncState.synced.dbValue;
    final localUpdatedAt = (row['updated_at'] as int?) ?? 0;
    if (!isSynced || localUpdatedAt > lwwMs) return false;
    await txn.update(
      table,
      {...updateValues, 'synced_at': syncedAt, 'updated_at': lwwMs},
      where: 'id = ? AND sync_status = ?',
      whereArgs: [id, SyncState.synced.dbValue],
    );
    return true;
  }

  /// Get-or-create d'un tuteur canonique en `SYNCED`, puis (ré)écriture du lien
  /// `student_parent`. Résolution ordonnée (renvoie l'id de tuteur résolu) :
  ///  1. par `id` canonique (valeur serveur autoritaire) → UPDATE si la ligne
  ///     locale est SYNCED (répercute p. ex. un téléphone corrigé côté serveur) ;
  ///  2. sinon par téléphone MAIS seulement si le local est un tuteur PROTÉGÉ
  ///     (provisoire, en attente de son propre ACK) → réutilisé pour le lien,
  ///     jamais écrasé (remap différé à son ACK). Un tuteur SYNCED d'un AUTRE id
  ///     est un individu distinct (même téléphone du foyer) → jamais fusionné ;
  ///  3. sinon INSERT du tuteur canonique en `SYNCED`.
  Future<String> _upsertSnapshotParent(
    DatabaseExecutor txn,
    String studentId,
    ParentSnapshotDto p,
    int lwwMs,
    int syncedAt,
  ) async {
    final fields = <String, Object?>{
      'first_name': p.firstName,
      'last_name': p.lastName,
      'surname': p.surname,
      'phone_number': p.phoneNumber,
      'email': p.email,
      'identification_number': p.identificationNumber,
    };

    final String parentId;
    final byId = await txn.query(
      'parents',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [p.id],
      limit: 1,
    );
    if (byId.isNotEmpty) {
      parentId = p.id;
      final isSynced =
          (byId.first['sync_status'] as String?) == SyncState.synced.dbValue;
      if (isSynced) {
        await txn.update(
          'parents',
          {...fields, 'synced_at': syncedAt, 'updated_at': lwwMs},
          where: 'id = ? AND sync_status = ?',
          whereArgs: [p.id, SyncState.synced.dbValue],
        );
      }
    } else {
      final byProvisionalPhone = await txn.query(
        'parents',
        columns: ['id'],
        where: 'phone_number = ? AND sync_status != ?',
        whereArgs: [p.phoneNumber, SyncState.synced.dbValue],
        limit: 1,
      );
      if (byProvisionalPhone.isNotEmpty) {
        parentId =
            byProvisionalPhone.first['id'] as String; // provisoire réutilisé
      } else {
        parentId = p.id;
        await txn.insert('parents', {
          'id': p.id,
          ...fields,
          'sync_status': SyncState.synced.dbValue,
          'synced_at': syncedAt,
          'updated_at': lwwMs,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    await txn.insert('student_parent', {
      'student_id': studentId,
      'parent_id': parentId,
      'relationship_type': p.relationshipType,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return parentId;
  }

  /// Réconcilie les liens `student_parent` d'un élève après hydratation : purge
  /// les liens vers des tuteurs **SYNCED** (gérés serveur) absents du jeu de
  /// l'agrégat (tuteur retiré du dossier côté serveur). Un lien vers un tuteur
  /// local PROTÉGÉ (provisoire) est une écriture locale — jamais purgé.
  Future<void> _pruneStudentParentLinks(
    DatabaseExecutor txn,
    String studentId,
    List<String> keepParentIds,
  ) async {
    final keepClause = keepParentIds.isEmpty
        ? ''
        : ' AND parent_id NOT IN (${sqlMarks(keepParentIds)})';
    await txn.rawDelete(
      'DELETE FROM student_parent WHERE student_id = ? AND parent_id IN '
      '(SELECT id FROM parents WHERE sync_status = ?)$keepClause',
      [studentId, SyncState.synced.dbValue, ...keepParentIds],
    );
  }

  /// Horloge LWW d'un agrégat snapshot : `updatedAt` (heure métier) s'il est
  /// présent, sinon repli sur `serverUpdatedAt`. Conversion ISO → epoch ms
  /// **tolérante** : si l'heure métier est malformée on retente `serverUpdatedAt`,
  /// puis en dernier ressort [fallback] — jamais de `FormatException` qui
  /// figerait le pull snapshot (cf. revue #21).
  static int _snapshotLwwMillis(
    String? updatedAt,
    String serverUpdatedAt, {
    required int fallback,
  }) {
    final primary = (updatedAt != null && updatedAt.isNotEmpty)
        ? updatedAt
        : serverUpdatedAt;
    return DateTime.tryParse(primary)?.millisecondsSinceEpoch ??
        DateTime.tryParse(serverUpdatedAt)?.millisecondsSinceEpoch ??
        fallback;
  }

  static int? _boolToInt(bool? value) => value == null ? null : (value ? 1 : 0);
}
