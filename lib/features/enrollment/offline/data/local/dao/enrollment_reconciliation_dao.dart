import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
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
      // ⚠️ NI `phone_number` NI `email` (ADR-015 F8, schéma v27).
      //
      // Le serveur les envoie toujours, mais rien ici ne les consomme : aucune
      // requête ne les nomme, et le mapper qui alimente l'écran les abandonne
      // (`StudentDetail` ne déclare ni l'un ni l'autre). Les écrire, c'était
      // poser de la donnée personnelle au repos sur chaque tablette du parc pour
      // un lecteur qui n'existe pas.
      //
      // Le tuteur, lui, garde les siens plus bas : `parents.phone_number` est la
      // clé d'unicité applicative du rapprochement RE/PRE, donc une donnée de
      // travail, pas un contact dormant.
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
        // Voir `studentUpdate` ci-dessus : ni téléphone ni e-mail. Les colonnes
        // restent déclarées au schéma (SQLite ne retire pas une colonne sans
        // reconstruire `students`, table centrale) ; elles restent NULL.
        'matriculation_number': s.matriculationNumber,
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
      // Sans ces deux lignes, une tablette neuve hydratée par le pull recevrait
      // le dossier ENTIER sauf « ancien élève » et la fiche santé : deux
      // colonnes à leur défaut, indiscernables d'une déclaration réelle. La
      // fiche santé, en particulier, disparaîtrait sans que rien ne le dise.
      'former_student': e.formerStudent ? 1 : 0,
      'medical_notes': e.medicalNotes,
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
    await _designateFrom(txn, e.studentId, agg.parents, resolvedParentIds);
    // L'agrégat porte l'ensemble COMPLET des tuteurs (contrat auto-suffisant) →
    // purge des liens vers des tuteurs SYNCED disparus du dossier serveur (les
    // liens vers un tuteur local protégé, non SYNCED, sont préservés).
    await _pruneStudentParentLinks(txn, e.studentId, resolvedParentIds);
    await _applySnapshotReductions(txn, e, syncedAt);

    return wroteEnrollment;
  }

  /// Réductions octroyées portées par l'agrégat (ADR-021 V1) → local.
  ///
  /// **Écrit seulement si la section est portée.** `null` dit « je n'en parle
  /// pas » — un serveur antérieur au champ, ou une portion non communiquée —
  /// et effacer sur ce silence ferait perdre au premier pull les octrois que
  /// le guichet vient de déclarer, avant même qu'ils soient poussés. `[]`, lui,
  /// dit « ce dossier n'en a aucune », et c'est un ordre légitime d'effacer.
  ///
  /// Écrit **hors du verrou LWW de la ligne** : les octrois ne vivent pas sur
  /// `enrollments`, et côté serveur en poser un ne touche même pas son
  /// `server_updated_at`. Les suspendre à l'horodatage de l'inscription les
  /// rendrait invisibles exactement dans le cas que la V2 va créer.
  Future<void> _applySnapshotReductions(
    DatabaseExecutor txn,
    EnrollmentSnapshotDto e,
    int syncedAt,
  ) async {
    final codes = e.reductionCodes;
    if (codes == null) return;

    await txn.delete(
      'enrollment_reductions',
      where: 'enrollment_id = ?',
      whereArgs: [e.id],
    );
    for (final code in codes.toSet()) {
      await txn.insert('enrollment_reductions', {
        'enrollment_id': e.id,
        'reduction_code': code,
        'updated_at': syncedAt,
      });
    }
  }

  /// Reflète en local une désignation de contact d'urgence **déjà acquittée par
  /// le serveur** (`204`).
  ///
  /// Sans elle, l'écran de consultation — intégralement local — garderait
  /// l'ancien contact jusqu'au prochain pull. Le serveur remonte bien le
  /// curseur de synchro du dossier, mais « finira par arriver » n'est pas une
  /// réponse quand quelqu'un vient de changer le numéro qu'on appellera en cas
  /// d'accident.
  ///
  /// **Démote puis promeut, dans une seule transaction** : l'index unique
  /// partiel n'admet qu'une ligne à `1` par élève, et promouvoir B pendant que
  /// A porte encore le drapeau le violerait. [parentId] à `null` retire la
  /// désignation sans en poser d'autre.
  Future<void> applyEmergencyContactDesignation({
    required String studentId,
    required String? parentId,
  }) async {
    await _db.transaction(
      (txn) =>
          _applyDesignationIn(txn, studentId: studentId, parentId: parentId),
    );
  }

  /// Corps partagé — appelé aussi depuis l'hydratation, qui tient déjà sa
  /// transaction. **Démote d'abord, promeut ensuite** : l'inverse violerait
  /// l'index à l'instant du flush.
  Future<void> _applyDesignationIn(
    DatabaseExecutor txn, {
    required String studentId,
    required String? parentId,
  }) async {
    await txn.update(
      'student_parent',
      {'emergency_contact': 0},
      where: 'student_id = ? AND emergency_contact = 1',
      whereArgs: [studentId],
    );
    if (parentId == null) return;
    await txn.update(
      'student_parent',
      {'emergency_contact': 1},
      where: 'student_id = ? AND parent_id = ?',
      whereArgs: [studentId, parentId],
    );
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
      // Rapprochement insensible au format d'écriture : le numéro pullé et
      // celui saisi hors ligne peuvent différer de mise en forme sans
      // désigner deux tuteurs.
      //
      // La clé normalisée écarte l'index `idx_parents_phone` : le filtre sur
      // `sync_status` est donc placé EN TÊTE pour que la normalisation ne
      // soit évaluée que sur les quelques tuteurs provisoires, et non sur
      // tout le carnet à chaque parent pullé (mesuré : ~3,2 s de plus sur un
      // pull de 3000 tuteurs, ramenés à ~0,45 s). Simple aide à
      // l'optimiseur : le résultat ne dépend pas de l'ordre des termes.
      final provisionalId = await findParentIdByPhone(
        txn,
        p.phoneNumber,
        whereSuffix: 'sync_status != ?',
        suffixArgs: [SyncState.synced.dbValue],
      );
      if (provisionalId != null) {
        parentId = provisionalId; // provisoire réutilisé
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

    // **`emergency_contact` n'est PAS écrit ici**, et c'est vital.
    //
    // Cette écriture est un `INSERT OR REPLACE`, et SQLite y résout les
    // conflits de TOUTE contrainte d'unicité — l'index partiel
    // `ux_emergency_contact_per_student` compris — en SUPPRIMANT la ligne en
    // conflit, jamais en refusant. Poser le drapeau à 1 sur un tuteur alors
    // qu'un autre le porte déjà pour cet élève ne ferait donc pas basculer un
    // booléen : cela ferait disparaître le LIEN entier de l'autre tuteur.
    //
    // Le tuteur perdu serait, qui plus est, celui qu'on protège le plus : une
    // fiche locale provisoire, que `_pruneStudentParentLinks` s'interdit de
    // purger précisément parce qu'elle porte une écriture non encore poussée.
    // Elle n'aurait même pas eu l'occasion d'être épargnée.
    //
    // La désignation est donc appliquée APRÈS toute la liste, en une passe
    // démote-puis-promeut (cf. `_designateFrom`).
    // **`INSERT OR IGNORE` puis `UPDATE` ciblé**, jamais `OR REPLACE`.
    //
    // `REPLACE` ne met pas la ligne à jour : il la SUPPRIME et en insère une
    // neuve. Les colonnes qu'on ne cite pas y reprennent donc leur défaut —
    // `emergency_contact` retomberait à 0 à chaque pull, effaçant en silence
    // une désignation locale qui attend son push. Ne pas écrire une colonne ne
    // suffit pas à la préserver sous ce mode.
    await txn.insert('student_parent', {
      'student_id': studentId,
      'parent_id': parentId,
      'relationship_type': p.relationshipType,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await txn.update(
      'student_parent',
      {'relationship_type': p.relationshipType},
      where: 'student_id = ? AND parent_id = ?',
      whereArgs: [studentId, parentId],
    );
    return parentId;
  }

  /// Applique la désignation « contact d'urgence » portée par l'agrégat, une
  /// fois TOUS ses liens écrits.
  ///
  /// En une passe, et jamais tuteur par tuteur : l'index unique partiel
  /// n'admet qu'une ligne à 1 par élève, et l'écriture des liens se fait en
  /// `INSERT OR REPLACE`, qui détruirait la ligne en conflit au lieu de la
  /// refuser (voir `_upsertSnapshotParent`).
  ///
  /// **Trois cas, et le troisième n'est pas le deuxième.** Un `true` désigne et
  /// démote le reste. Que des `false` : le serveur dit explicitement que
  /// personne n'est désigné, on démote. Que des `null` : c'est un serveur
  /// antérieur au champ, qui ne dit RIEN — on ne touche à rien, plutôt que de
  /// détruire une désignation locale qui attend peut-être son push.
  Future<void> _designateFrom(
    DatabaseExecutor txn,
    String studentId,
    List<ParentSnapshotDto> parents,
    List<String> resolvedParentIds,
  ) async {
    String? designated;
    var saysSomething = false;
    for (var i = 0; i < parents.length && i < resolvedParentIds.length; i++) {
      final flag = parents[i].emergencyContact;
      if (flag == null) continue;
      saysSomething = true;
      if (flag) designated = resolvedParentIds[i];
    }
    if (!saysSomething) return;
    await _applyDesignationIn(txn, studentId: studentId, parentId: designated);
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
