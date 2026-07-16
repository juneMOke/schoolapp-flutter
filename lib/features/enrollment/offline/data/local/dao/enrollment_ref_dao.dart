import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

/// Peuple les tables de référence Inscription (`ref_*`) et réconcilie les
/// `enrollments` depuis les PULL (miroir `openapi_enrollment_sync.yaml`).
/// Écriture seule, alimentée par `EnrollmentPullRepositoryImpl` — jamais par
/// l'UI. La grille tarifaire du bundle référentiel est confiée à
/// `FinanceLocalDao.replaceTariffsForYears` (table `ref_fee_tariffs`,
/// module Facturation).
class EnrollmentRefDao {
  final Database _db;

  const EnrollmentRefDao(this._db);

  /// Applique le bundle référentiel : années, cycles, niveaux (D1/D2).
  ///
  /// Le 200 du contrat renvoie **le bundle complet** (snapshot) : les cycles et
  /// niveaux des années couvertes par le bundle qui n'y figurent plus sont
  /// **purgés** (sinon une ligne supprimée côté serveur resterait fantôme pour
  /// toujours, le bundle always-200 étant re-caché en entier à chaque pull). La
  /// purge est
  /// **scopée aux années du bundle** — `ref_academic_years` n'est jamais
  /// purgée : le bundle est restreint à l'année active, or l'année N-1 doit
  /// survivre (références de la cohorte de réinscription). `is_current` est un
  /// snapshot : remis à zéro avant application pour ne jamais garder deux
  /// années « courantes ». Renvoie le nombre de lignes écrites.
  Future<int> upsertReferential(
    ReferentialBundleDto bundle, {
    required int syncedAt,
  }) async {
    final yearIds = <String>{
      for (final y in bundle.academicYears) y.id,
      for (final g in bundle.schoolLevelGroups) g.academicYearId,
    }.toList(growable: false);
    final groupIds = [for (final g in bundle.schoolLevelGroups) g.id];
    final levelIds = [for (final l in bundle.schoolLevels) l.id];

    await _db.transaction((txn) async {
      if (bundle.academicYears.isNotEmpty) {
        await txn.update('ref_academic_years', {'is_current': 0});
      }
      await _purgeScopedReferential(txn, yearIds, groupIds, levelIds);
      final batch = txn.batch();
      for (final y in bundle.academicYears) {
        batch.insert('ref_academic_years', {
          'id': y.id,
          'name': y.name,
          'start_date': y.startDate,
          'end_date': y.endDate,
          'is_current': y.isCurrent ? 1 : 0,
          'synced_at': syncedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final g in bundle.schoolLevelGroups) {
        batch.insert('ref_school_level_groups', {
          'id': g.id,
          'name': g.name,
          'code': g.code,
          'period_type': g.periodType,
          'academic_year_id': g.academicYearId,
          'display_order': g.displayOrder,
          'synced_at': syncedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final l in bundle.schoolLevels) {
        batch.insert('ref_school_levels', {
          'id': l.id,
          'name': l.name,
          'code': l.code,
          'level_group_id': l.levelGroupId,
          'display_order': l.displayOrder,
          'split_into_classrooms': l.splitIntoClassrooms ? 1 : 0,
          'synced_at': syncedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
    return bundle.academicYears.length +
        bundle.schoolLevelGroups.length +
        bundle.schoolLevels.length;
  }

  /// Évacue cycles et niveaux disparus du snapshot, sans sortir du périmètre
  /// des années couvertes par le bundle (un bundle sans année n'autorise
  /// aucune purge — symétrique du garde `is_current`).
  Future<void> _purgeScopedReferential(
    Transaction txn,
    List<String> yearIds,
    List<String> bundleGroupIds,
    List<String> bundleLevelIds,
  ) async {
    if (yearIds.isEmpty) return;
    // Scope des cycles = cycles locaux des années du bundle ∪ cycles du bundle
    // (capturé AVANT la purge : les niveaux d'un cycle supprimé partent aussi).
    final localGroups = await txn.query(
      'ref_school_level_groups',
      columns: ['id'],
      where: 'academic_year_id IN (${_marks(yearIds)})',
      whereArgs: yearIds,
    );
    final scopedGroupIds = <String>{
      for (final r in localGroups) r['id'] as String,
      ...bundleGroupIds,
    }.toList(growable: false);
    if (scopedGroupIds.isNotEmpty) {
      final keepLevels = bundleLevelIds.isEmpty
          ? ''
          : ' AND id NOT IN (${_marks(bundleLevelIds)})';
      await txn.delete(
        'ref_school_levels',
        where: 'level_group_id IN (${_marks(scopedGroupIds)})$keepLevels',
        whereArgs: [...scopedGroupIds, ...bundleLevelIds],
      );
    }
    final keepGroups = bundleGroupIds.isEmpty
        ? ''
        : ' AND id NOT IN (${_marks(bundleGroupIds)})';
    await txn.delete(
      'ref_school_level_groups',
      where: 'academic_year_id IN (${_marks(yearIds)})$keepGroups',
      whereArgs: [...yearIds, ...bundleGroupIds],
    );
  }

  static String _marks(List<Object?> args) =>
      List.filled(args.length, '?').join(', ');

  /// Remplace la cohorte N-1 (`ref_previous_year_students`). Sémantique
  /// snapshot : la cohorte est bornée/statique (pull complet always-200 à chaque
  /// cycle online, jamais de 304), le remplacement intégral évacue les radiés.
  /// Un 200 avec liste vide VIDE donc la table (cohorte réellement vidée côté
  /// serveur). Renvoie le nombre de lignes affectées : insérées, ou **purgées**
  /// quand le snapshot est vide (un wipe est un vrai changement local, pas un
  /// `notModified`).
  Future<int> replaceReenrollmentCohort(
    List<ReenrollmentCandidateDto> items, {
    required int syncedAt,
  }) async {
    var affected = items.length;
    await _db.transaction((txn) async {
      final removed = await txn.delete('ref_previous_year_students');
      if (items.isEmpty) affected = removed;
      final batch = txn.batch();
      for (final c in items) {
        batch.insert(
          'ref_previous_year_students',
          {
            'student_id': c.studentId,
            'matriculation_number': c.matriculationNumber,
            'first_name': c.firstName,
            'last_name': c.lastName,
            'surname': c.surname,
            'gender': c.gender,
            'date_of_birth': c.dateOfBirth,
            'birth_place': c.birthPlace,
            'previous_academic_year_id': c.previousAcademicYearId,
            'previous_school_level_id': c.previousSchoolLevelId,
            'previous_classroom_id': c.previousClassroomId,
            'guardian_name': c.guardianName,
            'guardian_phone': c.guardianPhone,
            'previous_balance_in_cents': c.previousBalanceInCents,
            'currency': c.currency,
            'synced_at': syncedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
    return affected;
  }

  /// Upsert delta des préinscriptions (`ref_pre_enrollments`). `updated_at`
  /// ISO-8601 du serveur converti en epoch ms local (colonne INTEGER) — le
  /// curseur de pull, lui, reste le `serverTime` opaque (jamais cette colonne).
  Future<int> upsertPreEnrollments(
    List<PreEnrollmentDto> items, {
    required int syncedAt,
  }) async {
    await applyInBatches(
      _db,
      items,
      apply: (txn, chunk) async {
        final batch = txn.batch();
        for (final p in chunk) {
          batch.insert('ref_pre_enrollments', {
            'id': p.id,
            'first_name': p.firstName,
            'last_name': p.lastName,
            'surname': p.surname,
            'gender': p.gender,
            'date_of_birth': p.dateOfBirth,
            'birth_place': p.birthPlace,
            'desired_school_level_id': p.desiredSchoolLevelId,
            'guardian_name': p.guardianName,
            'guardian_phone': p.guardianPhone,
            'updated_at': DateTime.parse(p.updatedAt).millisecondsSinceEpoch,
            'synced_at': syncedAt,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      },
    );
    return items.length;
  }

  // ── Lectures (seed RE/PRE depuis le local) ──────────────────────────────────

  /// `id` de l'année académique **courante** (`is_current = 1`) telle que
  /// peuplée par le pull référentiel. `null` = référentiel non encore synchronisé
  /// (base fraîche / hors-ligne). Sert à **scoper par saison** le marqueur de
  /// skip de la cohorte N-1 (invalidation automatique au rollover d'année).
  Future<String?> findCurrentAcademicYearId() async {
    final rows = await _db.query(
      'ref_academic_years',
      columns: ['id'],
      where: 'is_current = 1',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as String?;
  }

  /// Candidat de réinscription par `student_id` canonique (photo de départ du
  /// brouillon RE). `null` = cohorte non peuplée (pull dormant) ou élève absent.
  Future<ReenrollmentCandidate?> findReenrollmentCandidateByStudentId(
    String studentId,
  ) async {
    final rows = await _db.query(
      'ref_previous_year_students',
      where: 'student_id = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _candidateFromRow(rows.first);
  }

  /// Recherche des candidats à la réinscription (vivier N-1) filtrée par niveau.
  /// La cohorte ne stocke que `previous_school_level_id` : le filtre par *groupe*
  /// passe donc par les niveaux de ce groupe (référentiel local
  /// `ref_school_levels`). Le raffinage nom/DOB reste côté présentation (parité
  /// avec `searchByAcademicInfo`). Trié par nom pour une liste stable.
  Future<List<ReenrollmentCandidate>> searchReenrollmentCandidates({
    String? schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (schoolLevelId != null) {
      clauses.add('previous_school_level_id = ?');
      args.add(schoolLevelId);
    } else if (schoolLevelGroupId != null) {
      clauses.add(
        'previous_school_level_id IN '
        '(SELECT id FROM ref_school_levels WHERE level_group_id = ?)',
      );
      args.add(schoolLevelGroupId);
    }
    final where = clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    final rows = await _db.rawQuery(
      'SELECT * FROM ref_previous_year_students $where '
      'ORDER BY last_name, first_name',
      args,
    );
    return rows.map(_candidateFromRow).toList();
  }

  ReenrollmentCandidate _candidateFromRow(Map<String, Object?> r) =>
      ReenrollmentCandidate(
        studentId: r['student_id'] as String,
        matriculationNumber: r['matriculation_number'] as String,
        firstName: r['first_name'] as String,
        lastName: r['last_name'] as String,
        surname: r['surname'] as String?,
        gender: r['gender'] as String,
        dateOfBirth: r['date_of_birth'] as String,
        birthPlace: r['birth_place'] as String?,
        previousAcademicYearId: r['previous_academic_year_id'] as String?,
        previousSchoolLevelId: r['previous_school_level_id'] as String?,
        previousClassroomId: r['previous_classroom_id'] as String?,
        guardianName: r['guardian_name'] as String?,
        guardianPhone: r['guardian_phone'] as String?,
        previousBalanceInCents: (r['previous_balance_in_cents'] as int?) ?? 0,
        currency: r['currency'] as String?,
      );

  /// Préinscription par `id` (photo de départ du brouillon PRE). `null` =
  /// snapshot non peuplé (pull dormant) ou préinscription absente.
  Future<PreEnrollmentCandidate?> findPreEnrollmentById(String id) async {
    final rows = await _db.query(
      'ref_pre_enrollments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return PreEnrollmentCandidate(
      id: r['id'] as String,
      firstName: r['first_name'] as String,
      lastName: r['last_name'] as String,
      surname: r['surname'] as String?,
      gender: r['gender'] as String?,
      dateOfBirth: r['date_of_birth'] as String?,
      birthPlace: r['birth_place'] as String?,
      desiredSchoolLevelId: r['desired_school_level_id'] as String?,
      guardianName: r['guardian_name'] as String?,
      guardianPhone: r['guardian_phone'] as String?,
    );
  }

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
    final updatedMs = DateTime.parse(d.updatedAt).millisecondsSinceEpoch;
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
    final lwwMs = _snapshotLwwMillis(e.updatedAt, agg.serverUpdatedAt);

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
        : ' AND parent_id NOT IN (${_marks(keepParentIds)})';
    await txn.rawDelete(
      'DELETE FROM student_parent WHERE student_id = ? AND parent_id IN '
      '(SELECT id FROM parents WHERE sync_status = ?)$keepClause',
      [studentId, SyncState.synced.dbValue, ...keepParentIds],
    );
  }

  /// Horloge LWW d'un agrégat snapshot : `updatedAt` (heure métier) s'il est
  /// présent, sinon repli sur `serverUpdatedAt` (toujours fourni). ISO → epoch ms.
  static int _snapshotLwwMillis(String? updatedAt, String serverUpdatedAt) {
    final iso = (updatedAt != null && updatedAt.isNotEmpty)
        ? updatedAt
        : serverUpdatedAt;
    return DateTime.parse(iso).millisecondsSinceEpoch;
  }

  static int? _boolToInt(bool? value) => value == null ? null : (value ? 1 : 0);
}
