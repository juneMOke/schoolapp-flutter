import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

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
}) => OutboxDao(txn).enqueue(
  OutboxEntry(
    id: entryId,
    aggregateType: type,
    aggregateId: aggregateId,
    operation: OutboxOperation.upsert,
    payload: jsonEncode(payload),
    // Sans école, l'entrée deviendrait inéligible au flush scopé.
    schoolId: schoolId,
    createdAt: nowMs,
  ),
);
