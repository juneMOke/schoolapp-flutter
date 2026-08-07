import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_ack.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_pull_models.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_row.dart';

/// Accès sqflite aux tables du module Classe (`ref_classrooms`,
/// `ref_classroom_members` + événement `classroom_transfers`). Upsert du delta
/// de pull (CF2), lectures offline **composées** (CF3/CF4 : miroir ± transferts
/// pending), écriture-événement de transfert et application de l'ACK.
class ClassroomLocalDataSource {
  final Database _db;

  const ClassroomLocalDataSource(this._db);

  static const String classroomsTable = 'ref_classrooms';
  static const String membersTable = 'ref_classroom_members';
  static const String transfersTable = 'classroom_transfers';

  /// Classe courante COMPOSÉE d'un élève : le dernier transfert local **non
  /// synchronisé** gagne, sinon le miroir. Sous-requête corrélée (année portée
  /// par la ligne membre `m`), réutilisée par le roster et son flag pending.
  static const String _composedClassroomExpr =
      '''
    COALESCE(
      (SELECT t.to_classroom_id FROM $transfersTable t
         WHERE t.student_id = m.student_id
           AND t.academic_year_id = m.academic_year_id
           AND t.sync_status <> 'SYNCED'
         ORDER BY t.transferred_at DESC LIMIT 1),
      m.classroom_id
    )''';

  /// `1` si l'élève a un transfert local non synchronisé (⇒ il est dans la
  /// classe consultée VIA ce transfert : la pastille pending s'affiche).
  static const String _hasPendingExpr =
      '''
    EXISTS(
      SELECT 1 FROM $transfersTable t
       WHERE t.student_id = m.student_id
         AND t.academic_year_id = m.academic_year_id
         AND t.sync_status <> 'SYNCED'
    ) AS has_pending_transfer''';

  static const String _rosterOrderBy =
      'student_last_name COLLATE NOCASE ASC, '
      'student_middle_name COLLATE NOCASE ASC, '
      'student_first_name COLLATE NOCASE ASC';

  /// Upsert transactionnel (par lots) d'une page de classes pullées (CF2, flux
  /// `classrooms` — indépendant du roster). `synced_at` posé sur chaque ligne
  /// touchée (fraîcheur ADR-002). `REPLACE` sur la PK = idempotent.
  Future<void> upsertClassrooms({
    required List<ClassroomDto> classrooms,
    required int syncedAt,
  }) async {
    await applyInBatches(
      _db,
      classrooms,
      apply: (txn, chunk) async {
        final batch = txn.batch();
        for (final c in chunk) {
          batch.insert(
            classroomsTable,
            c.toMap(syncedAt: syncedAt),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
    );
  }

  /// Upsert transactionnel (par lots) d'une page de membres pullés (CF2, flux
  /// `classroom-members` — indépendant des classes). `synced_at` posé sur
  /// chaque ligne touchée (fraîcheur ADR-002). `REPLACE` sur la PK = idempotent.
  Future<void> upsertMembers({
    required List<ClassroomMemberDto> members,
    required int syncedAt,
  }) async {
    await applyInBatches(
      _db,
      members,
      apply: (txn, chunk) async {
        final batch = txn.batch();
        for (final m in chunk) {
          batch.insert(
            membersTable,
            m.toMap(syncedAt: syncedAt),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      },
    );
  }

  /// Classes d'une année (et niveau optionnel), triées par nom. Lecture directe
  /// des compteurs pré-agrégés — **sans charger le roster** (CF3).
  Future<List<ClassroomDto>> getClassrooms({
    required String academicYearId,
    String? schoolLevelId,
  }) async {
    final where = StringBuffer('academic_year_id = ?');
    final args = <Object?>[academicYearId];
    if (schoolLevelId != null) {
      where.write(' AND school_level_id = ?');
      args.add(schoolLevelId);
    }
    final rows = await _db.query(
      classroomsTable,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(ClassroomDto.fromMap).toList(growable: false);
  }

  /// Une classe par id (`null` si absente localement).
  Future<ClassroomDto?> getClassroomById(String classroomId) async {
    final rows = await _db.query(
      classroomsTable,
      where: 'id = ?',
      whereArgs: [classroomId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClassroomDto.fromMap(rows.first);
  }

  /// Roster ACTIVE **composé** d'une classe (CF3/CF4) : les élèves dont la classe
  /// courante (miroir ± transferts pending) vaut [classroomId]. Retire ceux
  /// partis (transfert pending sortant), ajoute ceux venus (transfert pending
  /// entrant, marqués `hasPendingTransfer`). Zéro jointure sur le snapshot.
  Future<List<ClassroomMemberDto>> getRoster(String classroomId) async {
    final rows = await _db.rawQuery(
      'SELECT m.*, $_hasPendingExpr '
      'FROM $membersTable m '
      "WHERE m.status = 'ACTIVE' AND $_composedClassroomExpr = ? "
      'ORDER BY $_rosterOrderBy',
      [classroomId],
    );
    return rows.map(ClassroomMemberDto.fromMap).toList(growable: false);
  }

  /// Recherche locale dans le roster ACTIVE composé (CF3) : filtre nom /
  /// post-nom / prénom, insensible à la casse — reproduit `members/search` sans
  /// réseau, sur la composition (transferts pending inclus).
  Future<List<ClassroomMemberDto>> searchRoster({
    required String classroomId,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getRoster(classroomId);
    final like = '%${trimmed.toLowerCase()}%';
    final rows = await _db.rawQuery(
      'SELECT m.*, $_hasPendingExpr '
      'FROM $membersTable m '
      "WHERE m.status = 'ACTIVE' AND $_composedClassroomExpr = ? AND ("
      'LOWER(m.student_first_name) LIKE ? OR '
      'LOWER(m.student_last_name) LIKE ? OR '
      'LOWER(m.student_middle_name) LIKE ?) '
      'ORDER BY $_rosterOrderBy',
      [classroomId, like, like, like],
    );
    return rows.map(ClassroomMemberDto.fromMap).toList(growable: false);
  }

  /// Écrit l'événement de transfert **et** enfile l'outbox dans **une**
  /// transaction (régime A, patron `finance_payment_write_dao`). **Aucun UPDATE
  /// du miroir `ref_classroom_members`** : la classe courante se compose à la
  /// lecture. `REPLACE` sur la PK = idempotent (rejeu d'écriture sûr).
  Future<void> recordTransferWithOutbox({
    required ClassroomTransferRow row,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        transfersTable,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Transferts **SYNCED** d'un élève sur l'année, triés par `transferred_at`
  /// croissant (F6) : bornes des intervalles d'appartenance du dénominateur
  /// d'assiduité. SYNCED seulement — le calcul par intervalles n'est fiable
  /// qu'une fois l'historique consolidé (bootstrapComplete des transferts).
  Future<List<ClassroomTransferRow>> getStudentSyncedTransfers({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      transfersTable,
      where: 'student_id = ? AND academic_year_id = ? AND sync_status = ?',
      whereArgs: [studentId, academicYearId, SyncState.synced.dbValue],
      orderBy: 'transferred_at ASC',
    );
    return rows.map(ClassroomTransferRow.fromMap).toList(growable: false);
  }

  /// Applique un lot de transferts **pullés** (CF4/F5) — SYNCED, idempotents
  /// (`REPLACE` sur la PK). Le `school_level_id` (absent du contrat) est résolu
  /// depuis `ref_classrooms(to)` (`''` si la classe n'est pas encore en base :
  /// champ non lu pour un SYNCED). Renvoie le nombre de lignes appliquées.
  ///
  /// ⚠ N'écrit **que** `classroom_transfers` — jamais le miroir : l'appartenance
  /// arrive par le pull de `ref_classroom_members`. Un transfert SYNCED ne
  /// compose pas (sa vérité est déjà dans le miroir) ; il sert les intervalles
  /// d'assiduité (F6).
  Future<int> applyPulledTransfers(
    List<ClassroomTransferDeltaDto> deltas,
    int syncedAt,
  ) async {
    if (deltas.isEmpty) return 0;
    var applied = 0;
    await _db.transaction((txn) async {
      for (final d in deltas) {
        final level = await txn.query(
          classroomsTable,
          columns: ['school_level_id'],
          where: 'id = ?',
          whereArgs: [d.toClassroomId],
          limit: 1,
        );
        final schoolLevelId = level.isEmpty
            ? ''
            : (level.first['school_level_id'] as String?) ?? '';
        await txn.insert(
          transfersTable,
          d.toRow(syncedAt: syncedAt, schoolLevelId: schoolLevelId).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        applied++;
      }
    });
    return applied;
  }

  /// Applique l'ACK serveur (CF4 §4.3) en **une** transaction : repositionne le
  /// miroir (appartenance canonique), remplace les compteurs des DEUX classes,
  /// puis scelle le transfert SYNCED — passage de témoin atomique.
  ///
  /// SYNCED **seulement si** le miroir a bien été repositionné (la membership a
  /// touché une ligne). Sinon on laisse pending : la composition à la lecture
  /// continue d'afficher l'élève dans la destination (sens de panne
  /// conservateur), la vérité arrivera au prochain pull du roster.
  Future<void> applyTransferAck(
    ClassroomTransferAck ack, {
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      // `membership` absente (rejeu d'un transfert dont l'appartenance serveur
      // n'existe plus) : rien à repositionner. On retombe sur le même sens de
      // panne conservateur qu'un update à 0 ligne — le transfert reste pending,
      // la vérité viendra du prochain pull du roster.
      final m = ack.membership;
      final updated = m == null
          ? 0
          : await txn.update(
              membersTable,
              {
                'classroom_id': m.classroomId,
                if (m.status != null) 'status': m.status,
                'synced_at': nowMs,
              },
              where: 'student_id = ? AND academic_year_id = ?',
              whereArgs: [m.studentId, m.academicYearId],
            );

      // Compteurs recalculés, autoritaires (ADR-002) — on remplace le miroir,
      // on ne dérive jamais un compteur local.
      for (final c in ack.classrooms) {
        await txn.update(
          classroomsTable,
          {
            'total_count': c.totalCount,
            'female_count': c.femaleCount,
            'male_count': c.maleCount,
            if (c.capacity != null) 'capacity': c.capacity,
            'synced_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [c.id],
        );
      }

      if (updated == 0) return; // miroir non repositionné → on garde pending
      await txn.update(
        transfersTable,
        {
          'sync_status': SyncState.synced.dbValue,
          'server_updated_at': ack.serverUpdatedAt,
          'synced_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [ack.transferId],
      );
    });
  }

  /// Classe courante **composée** d'un élève (CF3/CF4, cf. [_composedClassroomExpr])
  /// pour une année : un transfert local non synchronisé gagne, sinon le
  /// miroir. `null` si l'élève n'a pas (encore) de ligne membre locale pour
  /// cette année (ex. roster pas encore pullé).
  ///
  /// Le modèle suppose une seule ligne `ref_classroom_members` par
  /// `(student_id, academic_year_id)` (aucune contrainte SQL ne l'impose) —
  /// `ORDER BY updated_at DESC` sert de filet déterministe (ligne la plus
  /// récemment mutée) plutôt que l'ordre physique arbitraire de SQLite, si
  /// cette hypothèse était un jour violée.
  Future<String?> getCurrentClassroomId({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT $_composedClassroomExpr AS classroom_id '
      'FROM $membersTable m '
      'WHERE m.student_id = ? AND m.academic_year_id = ? '
      'ORDER BY m.updated_at DESC LIMIT 1',
      [studentId, academicYearId],
    );
    if (rows.isEmpty) return null;
    return rows.first['classroom_id'] as String?;
  }

  /// Nombre d'élèves ACTIVE d'une classe (effectif pour le taux dérivé AF-3).
  Future<int> countActiveRoster(String classroomId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $membersTable '
      'WHERE classroom_id = ? AND status = ?',
      [classroomId, 'ACTIVE'],
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
