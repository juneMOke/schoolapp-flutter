import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les entrées d'outbox du programme : quatre agrégats, des identifiants
/// d'entrée **déterministes**.
///
/// Un geste remplace l'entrée encore en attente du même objet : la fiche d'un
/// chapitre n'attend jamais qu'une fois (son dernier état), et sa suppression
/// remplace une fiche jamais partie ; l'ordre d'un cours n'attend qu'une
/// liste ; l'ajout puis le retrait d'une note jamais envoyée n'en font qu'un.
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

  /// Neutralise les entrées [ids] qui n'ont plus rien à pousser (l'objet
  /// n'existera jamais côté serveur), quel que soit leur statut.
  static Future<void> neutralize(DatabaseExecutor db, List<String> ids) async {
    if (ids.isEmpty) return;
    final marks = List.filled(ids.length, '?').join(', ');
    await db.update(
      OutboxDao.table,
      {'status': OutboxStatus.acked.dbValue},
      where: 'id IN ($marks) AND status <> ?',
      whereArgs: [...ids, OutboxStatus.acked.dbValue],
    );
  }

  /// Neutralise les gestes en attente des notes et ressources de
  /// [chapitreId] : le chapitre part, le serveur les emporte avec lui.
  static Future<void> neutralizeChildren(
    DatabaseExecutor db,
    String chapitreId,
  ) async {
    await db.update(
      OutboxDao.table,
      {'status': OutboxStatus.acked.dbValue},
      where: 'aggregate_type IN (?, ?) AND aggregate_id = ? AND status <> ?',
      whereArgs: [
        noteType,
        ressourceType,
        chapitreId,
        OutboxStatus.acked.dbValue,
      ],
    );
  }
}
