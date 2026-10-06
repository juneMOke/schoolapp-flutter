import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les entrées d'outbox du programme : quatre agrégats, des identifiants
/// d'entrée **déterministes**.
///
/// Un geste remplace l'entrée encore en attente du même objet : la fiche d'un
/// chapitre n'attend jamais qu'une fois (son dernier état), et sa suppression
/// remplace une fiche en attente ; l'ordre d'un cours n'attend qu'une liste.
class ProgrammeOutbox {
  ProgrammeOutbox._();

  /// Fiche d'un chapitre, ou sa suppression.
  static const String chapitreType = 'CHAPITRE';

  /// L'ordre des chapitres d'un cours.
  static const String ordreType = 'CHAPITRE_ORDRE';

  /// Ajout ou suppression d'une note de séance.
  static const String noteType = 'CHAPITRE_NOTE';

  /// Ajout ou retrait d'une ressource.
  static const String ressourceType = 'CHAPITRE_RESSOURCE';

  static String chapitreEntry(String chapitreId) => '$chapitreType:$chapitreId';
  static String ordreEntry(String coursId) => '$ordreType:$coursId';
  static String noteEntry(String noteId) => '$noteType:$noteId';
  static String ressourceEntry(String ressourceId) =>
      '$ressourceType:$ressourceId';

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

  /// Retire de la file les gestes des notes et ressources de [chapitreId] :
  /// le chapitre part, le serveur les emporte avec lui.
  static Future<void> discardChildren(DatabaseExecutor db, String chapitreId) =>
      db.delete(
        OutboxDao.table,
        where: 'aggregate_type IN (?, ?) AND aggregate_id = ?',
        whereArgs: [noteType, ressourceType, chapitreId],
      );

  /// Retire [chapitreId] du geste d'ordre de [coursId] encore en attente :
  /// le serveur refuserait (409) une liste qui cite un chapitre qu'il ne
  /// connaîtra jamais — indéfiniment.
  static Future<void> detachFromOrdre(
    DatabaseExecutor db, {
    required String coursId,
    required String chapitreId,
  }) async {
    final entryId = ordreEntry(coursId);
    final rows = await db.query(
      OutboxDao.table,
      columns: ['payload'],
      where: 'id = ? AND status <> ?',
      whereArgs: [entryId, OutboxStatus.acked.dbValue],
    );
    if (rows.isEmpty) return;
    final payload = jsonDecode(rows.single['payload'] as String);
    if (payload is! Map<String, dynamic>) return;
    final ids = payload['chapitreIds'];
    if (ids is! List || !ids.contains(chapitreId)) return;
    payload['chapitreIds'] = [
      for (final id in ids)
        if (id != chapitreId) id,
    ];
    await db.update(
      OutboxDao.table,
      {'payload': jsonEncode(payload)},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }
}
