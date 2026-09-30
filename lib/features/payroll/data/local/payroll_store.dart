import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_lww.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

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
      'sync_status': StaffSyncState.pending.dbValue,
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

  /// La ligne [key] attend-elle encore son envoi ? Le pull ne l'écrase pas.
  static Future<bool> isPending(
    DatabaseExecutor txn,
    String table,
    PayrollRowKey key,
  ) async {
    final rows = await txn.query(
      table,
      columns: ['sync_status'],
      where: where(key),
      whereArgs: args(key),
    );
    return rows.isNotEmpty &&
        rows.single['sync_status'] == StaffSyncState.pending.dbValue;
  }

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
            (failed ? StaffSyncState.failed : StaffSyncState.synced).dbValue,
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
    StaffSyncState state, {
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
