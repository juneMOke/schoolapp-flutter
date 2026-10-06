import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le corps d'une requête, l'auteur du geste à sa racine — la valeur que la
/// garde d'attribution du serveur compare au jeton.
/// L'auteur d'une entrée, `null` si elle n'en porte pas — pour les routes
/// qui le prennent en paramètre (`?authorId=`, les suppressions).
String? outboxAuthorOf(OutboxEntry entry) {
  final author = outboxAuthorUidOf(entry.payload);
  return author == kUnattributedOutboxAuthor ? null : author;
}

/// Le corps enveloppé du contrat : `{authorId, <key>: body}` — la fiche sous
/// `chapitre`, la note sous `note` (comme `{authorId, expense}`).
Map<String, Object?> outboxEnvelope(
  String key,
  Map<String, Object?> body,
  OutboxEntry entry,
) => withOutboxAuthor({key: body}, entry);

Map<String, Object?> withOutboxAuthor(
  Map<String, Object?> body,
  OutboxEntry entry,
) {
  final author = outboxAuthorUidOf(entry.payload);
  return author == kUnattributedOutboxAuthor
      ? body
      : {...body, kOutboxAuthorIdKey: author};
}

/// Met un geste du programme en file, dans la transaction de l'appelant.
/// L'identifiant d'entrée est déterministe (`ProgrammeOutbox`) : un geste
/// remplace l'entrée encore en attente du même objet.
Future<void> enqueueProgrammeGesture(
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
