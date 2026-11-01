import 'dart:math' as math;

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/data/datasources/cotes_local_data_source.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_push_models.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_saisie_row.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le chemin d'écriture des cellules. Une saisie et son entrée d'outbox tiennent
/// dans une seule transaction : jamais l'une sans l'autre.
class CotesWriteLocalDataSource {
  final Database _db;

  const CotesWriteLocalDataSource(this._db);

  static const String _table = CotesLocalDataSource.table;
  static const String _keyWhere =
      'student_id = ? AND cours_id = ? AND colonne_id = ?';

  static List<Object> _keyArgs(CoteCellKey key) => [
    key.studentId,
    key.coursId,
    key.colonneId,
  ];

  /// Crée la ligne si la cellule n'existait pas : une cellule jamais saisie et
  /// sans valeur calculée n'a pas de ligne.
  Future<void> _ensureRow(
    DatabaseExecutor executor,
    String classroomId,
    CoteCellKey key,
  ) => executor.insert(_table, {
    'student_id': key.studentId,
    'cours_id': key.coursId,
    'colonne_id': key.colonneId,
    'classroom_id': classroomId,
    'examen': key.examen ? 1 : 0,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);

  /// Pose le brouillon et enfile son envoi. L'horloge est **monotone** : une
  /// saisie doit toujours battre la précédente et ce que le serveur a déjà
  /// écrit, même si l'horloge de la tablette a reculé. Rend le jeton posé.
  Future<int> saveDraft({
    required String classroomId,
    required CoteCellKey key,
    required double? valeur,
    required String authorId,
    required int nowMs,
    required OutboxEntry entry,
  }) => _db.transaction((txn) async {
    await _ensureRow(txn, classroomId, key);
    final rows = await txn.query(
      _table,
      columns: ['draft_updated_at', 'server_updated_at'],
      where: _keyWhere,
      whereArgs: _keyArgs(key),
    );
    final lastDraft = rows.first['draft_updated_at'] as int? ?? 0;
    final lastServer = rows.first['server_updated_at'] as int? ?? 0;
    final at = math.max(nowMs, math.max(lastDraft, lastServer) + 1);
    await txn.update(
      _table,
      {
        'has_draft': 1,
        'draft_valeur': valeur,
        'draft_updated_at': at,
        'invalid_raw': null,
        'sync_status': SyncState.pendingSync.dbValue,
        'rejection_reason': null,
        'author_id': authorId,
        'superseded_at': null,
      },
      where: _keyWhere,
      whereArgs: _keyArgs(key),
    );
    await OutboxDao(txn).enqueue(entry);
    return at;
  });

  /// Une frappe hors barème : gardée, jamais envoyée. Le brouillon valide
  /// éventuel reste en file.
  Future<void> saveInvalid({
    required String classroomId,
    required CoteCellKey key,
    required String raw,
  }) => _db.transaction((txn) async {
    await _ensureRow(txn, classroomId, key);
    await txn.update(
      _table,
      {'invalid_raw': raw},
      where: _keyWhere,
      whereArgs: _keyArgs(key),
    );
  });

  Future<void> clearInvalid(CoteCellKey key) => _db.update(
    _table,
    {'invalid_raw': null},
    where: _keyWhere,
    whereArgs: _keyArgs(key),
  );

  /// Renonce à une cote refusée : la cellule revient à ce que dit le serveur.
  Future<void> discardRejected(CoteCellKey key) => _db.update(
    _table,
    {
      'has_draft': 0,
      'draft_valeur': null,
      'draft_updated_at': null,
      'sync_status': SyncState.synced.dbValue,
      'rejection_reason': null,
    },
    where: '$_keyWhere AND sync_status = ?',
    whereArgs: [..._keyArgs(key), SyncState.syncError.dbValue],
  );

  /// Les plus anciennes lignes en attente de cet auteur dans cette classe.
  Future<List<CoteLineDto>> pendingLines({
    required String classroomId,
    required String authorId,
    required int limit,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'classroom_id = ? AND author_id = ? AND sync_status = ?',
      whereArgs: [classroomId, authorId, SyncState.pendingSync.dbValue],
      orderBy: 'draft_updated_at ASC',
      limit: limit,
    );
    return [
      for (final row in rows)
        CoteLineDto(
          key: coteKeyFromRow(row),
          valeur: (row['draft_valeur'] as num?)?.toDouble(),
          updatedAtMs: row['draft_updated_at'] as int,
        ),
    ];
  }

  Future<int> pendingCount({
    required String classroomId,
    required String authorId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS n FROM $_table '
      'WHERE classroom_id = ? AND author_id = ? AND sync_status = ?',
      [classroomId, authorId, SyncState.pendingSync.dbValue],
    );
    return rows.first['n'] as int? ?? 0;
  }

  /// Accepté ou dépassé : la cellule reprend l'état du serveur. Gardé sur le
  /// jeton envoyé : une saisie posée pendant le vol reste à envoyer.
  Future<void> applyServerValue({
    required CoteCellKey key,
    required int pushedAt,
    required double? valeur,
    required int? serverUpdatedAtMs,
    required bool superseded,
    required int nowMs,
  }) => _db.update(
    _table,
    {
      'server_cote': valeur,
      'server_updated_at': serverUpdatedAtMs ?? pushedAt,
      'has_draft': 0,
      'draft_valeur': null,
      'draft_updated_at': null,
      'sync_status': SyncState.synced.dbValue,
      'rejection_reason': null,
      if (superseded) 'superseded_at': nowMs,
    },
    where: '$_keyWhere AND draft_updated_at = ? AND sync_status = ?',
    whereArgs: [..._keyArgs(key), pushedAt, SyncState.pendingSync.dbValue],
  );

  /// Refus définitif : le brouillon reste, c'est la seule trace de la valeur.
  Future<void> markRejected({
    required CoteCellKey key,
    required int pushedAt,
    required String? reason,
  }) => _db.update(
    _table,
    {'sync_status': SyncState.syncError.dbValue, 'rejection_reason': reason},
    where: '$_keyWhere AND draft_updated_at = ? AND sync_status = ?',
    whereArgs: [..._keyArgs(key), pushedAt, SyncState.pendingSync.dbValue],
  );

  /// Les cellules remplacées par une écriture plus récente, à signaler une fois.
  Future<List<CoteCellKey>> takeSuperseded(String classroomId) =>
      _db.transaction((txn) async {
        final rows = await txn.query(
          _table,
          where: 'classroom_id = ? AND superseded_at IS NOT NULL',
          whereArgs: [classroomId],
        );
        if (rows.isEmpty) return const [];
        await txn.update(
          _table,
          {'superseded_at': null},
          where: 'classroom_id = ? AND superseded_at IS NOT NULL',
          whereArgs: [classroomId],
        );
        return rows.map(coteKeyFromRow).toList(growable: false);
      });
}
