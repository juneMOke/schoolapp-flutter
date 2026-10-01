import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_lww.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une ligne de table désignée par sa clé (`colonne → valeur`).
typedef PayrollRowKey = Map<String, Object?>;

/// Ce qu'une écriture locale met en file avec elle.
class PayrollQueued {
  final String entryId;
  final String aggregateType;
  final String aggregateId;
  final Map<String, dynamic> payload;
  final OutboxOperation operation;

  const PayrollQueued({
    required this.entryId,
    required this.aggregateType,
    required this.aggregateId,
    required this.payload,
    this.operation = OutboxOperation.upsert,
  });
}

/// Le squelette partagé des écritures locales de la paie : une ligne et son
/// entrée d'outbox **dans la même transaction**, et l'issue d'un envoi jugée
/// sur l'horloge envoyée.
///
/// Trois régimes s'y appuient : le dernier écrit gagne (réglages, profil,
/// éléments variables), le fait (avance, versement) et le geste.
class PayrollStore {
  final DatabaseExecutor _db;

  const PayrollStore(this._db);

  DatabaseExecutor get db => _db;

  /// Exécute [body] dans une transaction — ou dans celle qui est déjà ouverte.
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) body) {
    final db = _db;
    return db is Database ? db.transaction(body) : body(db);
  }

  static String where(PayrollRowKey key) =>
      key.keys.map((column) => '$column = ?').join(' AND ');

  static List<Object?> args(PayrollRowKey key) => key.values.toList();

  /// Met à jour la ligne [key], ou l'insère ; rend `true` si elle existait.
  static Future<bool> upsert(
    DatabaseExecutor txn,
    String table,
    PayrollRowKey key,
    Map<String, Object?> columns,
  ) async {
    final updated = await txn.update(
      table,
      columns,
      where: where(key),
      whereArgs: args(key),
    );
    if (updated > 0) return true;
    await txn.insert(table, {...key, ...columns});
    return false;
  }

  /// Écrit la ligne en attente d'envoi et met [queued] en file.
  Future<void> write(
    String table,
    PayrollRowKey key,
    Map<String, Object?> columns,
    PayrollQueued queued, {
    required String schoolId,
    required int nowMs,
  }) => transaction((txn) async {
    await upsert(txn, table, key, {
      ...columns,
      'sync_status': RecordSyncState.pending.dbValue,
      'sync_error': null,
      'sync_error_code': null,
    });
    await enqueue(txn, queued, schoolId: schoolId, nowMs: nowMs);
  });

  static Future<void> enqueue(
    DatabaseExecutor txn,
    PayrollQueued queued, {
    required String schoolId,
    required int nowMs,
  }) => OutboxDao(txn).enqueue(
    OutboxEntry(
      id: queued.entryId,
      aggregateType: queued.aggregateType,
      aggregateId: queued.aggregateId,
      operation: queued.operation,
      payload: jsonEncode(queued.payload),
      schoolId: schoolId,
      createdAt: nowMs,
    ),
  );

  /// La colonne `effective_status` d'une ligne de fait ou de geste : une
  /// ligne encore « en attente » dont l'entrée d'outbox (`<type>:<id>`) a été
  /// abandonnée par le moteur (`SYNC_ERROR`, poison) se lit **refusée** —
  /// sinon elle resterait « en vol » à jamais, et tout ce qui l'attend avec
  /// elle. `outbox_error` porte alors la dernière erreur du moteur.
  static String effectiveStatusColumns(String alias, String type) {
    final entry =
        '(SELECT o.status FROM ${OutboxDao.table} o '
        "WHERE o.id = '$type:' || $alias.id)";
    final error =
        '(SELECT o.last_error FROM ${OutboxDao.table} o '
        "WHERE o.id = '$type:' || $alias.id)";
    return "CASE WHEN $alias.sync_status = '${RecordSyncState.pending.dbValue}' "
        "AND $entry = '${OutboxStatus.syncError.dbValue}' "
        "THEN '${RecordSyncState.failed.dbValue}' "
        'ELSE $alias.sync_status END AS effective_status, '
        '$error AS outbox_error';
  }

  /// L'état effectif lu par [effectiveStatusColumns].
  static RecordSyncState effectiveState(Map<String, Object?> row) =>
      RecordSyncState.fromDb(
        (row['effective_status'] ?? row['sync_status']) as String?,
      );

  /// L'erreur effective : celle rangée par le handler, sinon celle du moteur.
  static String? effectiveError(Map<String, Object?> row) =>
      (row['sync_error'] ??
              (effectiveState(row) == RecordSyncState.failed
                  ? row['outbox_error']
                  : null))
          as String?;

  /// La ligne [key] attend-elle encore son envoi ? Le pull ne l'écrase pas.
  ///
  /// Une saisie « dernier écrit gagne » ([saisieType], [saisieKey]) n'attend
  /// vraiment que si l'une de ses entrées est **encore en file** : une saisie
  /// que le moteur a abandonnée rend la ligne, et la descente suivante
  /// l'écrase — sinon la tablette garderait pour toujours une valeur que le
  /// serveur n'a jamais acceptée.
  static Future<bool> isPending(
    DatabaseExecutor txn,
    String table,
    PayrollRowKey key, {
    required String saisieType,
    required String saisieKey,
  }) async {
    final rows = await txn.query(
      table,
      columns: ['sync_status'],
      where: where(key),
      whereArgs: args(key),
    );
    if (rows.isEmpty ||
        rows.single['sync_status'] != RecordSyncState.pending.dbValue) {
      return false;
    }
    final queued = await txn.rawQuery(
      'SELECT 1 FROM ${OutboxDao.table} WHERE status = ? AND id LIKE ? '
      'LIMIT 1',
      [OutboxStatus.pending.dbValue, '$saisieType:$saisieKey@%'],
    );
    return queued.isNotEmpty;
  }

  /// La colonne `effective_status` d'une saisie « dernier écrit gagne » :
  /// « en attente » sans aucune entrée encore en file se lit **refusée**.
  /// [keyExpression] est l'expression SQL de la clé de saisie.
  static String lwwEffectiveStatusColumn(
    String saisieType,
    String keyExpression,
  ) =>
      "CASE WHEN sync_status = '${RecordSyncState.pending.dbValue}' "
      'AND NOT EXISTS (SELECT 1 FROM ${OutboxDao.table} o '
      "WHERE o.status = '${OutboxStatus.pending.dbValue}' "
      "AND o.id LIKE '$saisieType:' || $keyExpression || '@%') "
      "THEN '${RecordSyncState.failed.dbValue}' "
      'ELSE sync_status END AS effective_status';

  /// L'issue d'un envoi « dernier écrit gagne » : accusé ou refusé. Sans
  /// effet si la ligne a été retouchée pendant le vol — rend alors `false` :
  /// la saisie plus récente partira avec sa propre entrée.
  Future<bool> settleLww(
    String table,
    PayrollRowKey key, {
    required String sentClientUpdatedAt,
    required bool failed,
    String? code,
    String? reason,
    Map<String, Object?> serverColumns = const {},
  }) => transaction((txn) async {
    final rows = await txn.query(
      table,
      columns: ['client_updated_at'],
      where: where(key),
      whereArgs: args(key),
    );
    if (rows.isEmpty ||
        !StaffLww.sameInstant(
          rows.single['client_updated_at'] as String?,
          sentClientUpdatedAt,
        )) {
      return false;
    }
    await txn.update(
      table,
      {
        ...serverColumns,
        'sync_status':
            (failed ? RecordSyncState.failed : RecordSyncState.synced).dbValue,
        'sync_error': reason,
        'sync_error_code': code,
      },
      where: where(key),
      whereArgs: args(key),
    );
    return true;
  });

  /// L'issue d'un envoi qui ne se retouche pas (fait, geste).
  Future<void> mark(
    String table,
    PayrollRowKey key,
    RecordSyncState state, {
    String? code,
    String? reason,
    Map<String, Object?> extra = const {},
  }) => _db.update(
    table,
    {
      ...extra,
      'sync_status': state.dbValue,
      'sync_error': reason,
      'sync_error_code': code,
    },
    where: where(key),
    whereArgs: args(key),
  );
}
