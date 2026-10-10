import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

// Les gestes à **identifiant d'entrée déterministe** : un geste remplace
// l'entrée encore en attente du même objet, qui n'attend donc jamais qu'une
// fois (son dernier état). Partagé par les modules qui écrivent ainsi (le
// programme de cours, le journal de classe).

/// L'auteur d'une entrée, `null` si elle n'en porte pas — pour les routes
/// qui le prennent en paramètre (`?authorId=`, les suppressions).
String? outboxAuthorOf(OutboxEntry entry) {
  final author = outboxAuthorUidOf(entry.payload);
  return author == kUnattributedOutboxAuthor ? null : author;
}

/// Le corps enveloppé du contrat : `{authorId, <key>: body}` — la fiche sous
/// `chapitre`, l'entrée du journal sous `entry` (comme `{authorId, expense}`).
Map<String, Object?> outboxEnvelope(
  String key,
  Map<String, Object?> body,
  OutboxEntry entry,
) => withOutboxAuthor({key: body}, entry);

/// Le corps d'une requête, l'auteur du geste à sa racine — la valeur que la
/// garde d'attribution du serveur compare au jeton.
Map<String, Object?> withOutboxAuthor(
  Map<String, Object?> body,
  OutboxEntry entry,
) {
  final author = outboxAuthorUidOf(entry.payload);
  return author == kUnattributedOutboxAuthor
      ? body
      : {...body, kOutboxAuthorIdKey: author};
}

/// Met un geste en file, dans la transaction de l'appelant. [entryId] est
/// déterministe : le geste remplace l'entrée encore en attente du même objet.
Future<void> enqueueOutboxGesture(
  DatabaseExecutor txn, {
  required String entryId,
  required String type,
  required String aggregateId,
  required Map<String, Object?> payload,
  required String? schoolId,
  required int nowMs,
  String? authorId,
}) => OutboxDao(txn).enqueue(
  OutboxEntry(
    id: entryId,
    aggregateType: type,
    aggregateId: aggregateId,
    operation: OutboxOperation.upsert,
    // L'auteur à la racine : sur tablette partagée, le moteur ne pousse que
    // les gestes du compte connecté (`isForeignOutboxAuthor`).
    payload: jsonEncode({...payload, kOutboxAuthorIdKey: ?authorId}),
    // Sans école, l'entrée deviendrait inéligible au flush scopé.
    schoolId: schoolId,
    createdAt: nowMs,
  ),
);

/// Ce qu'un module demande à la file sur ses propres gestes.
abstract final class OutboxGestures {
  /// Une entrée de [type] sur [aggregateId] attend-elle encore ?
  static Future<bool> hasPending(
    DatabaseExecutor db, {
    required String type,
    required String aggregateId,
  }) async {
    final rows = await db.query(
      OutboxDao.table,
      columns: ['1'],
      where: 'aggregate_type = ? AND aggregate_id = ? AND status = ?',
      whereArgs: [type, aggregateId, OutboxStatus.pending.dbValue],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// L'entrée [entryId] a-t-elle été remplacée par un geste plus récent
  /// depuis l'envoi de celle créée à [sentCreatedAt] ?
  static Future<bool> replacedSince(
    DatabaseExecutor db,
    String entryId,
    int sentCreatedAt,
  ) async {
    final rows = await db.query(
      OutboxDao.table,
      columns: ['1'],
      where: 'id = ? AND status = ? AND created_at <> ?',
      whereArgs: [entryId, OutboxStatus.pending.dbValue, sentCreatedAt],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Retire de la file les entrées [ids], devenues sans objet.
  ///
  /// **Supprimées, et non passées « acquittées »** : une entrée en vol que le
  /// moteur reprogramme ensuite (`reschedule` ne regarde que l'identifiant et
  /// le `created_at`) repasserait en attente et ressusciterait le geste.
  /// Supprimée, elle ne laisse rien à reprogrammer.
  static Future<void> discard(DatabaseExecutor db, List<String> ids) async {
    if (ids.isEmpty) return;
    final marks = List.filled(ids.length, '?').join(', ');
    await db.delete(OutboxDao.table, where: 'id IN ($marks)', whereArgs: ids);
  }
}
