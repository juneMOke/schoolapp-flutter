import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/pending_evaluation_chapitres.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_purge.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écritures locales d'un chapitre et de l'ordre du programme — **toujours
/// avec leur entrée d'outbox, dans la même transaction**.
class ChapitreWriteDao {
  final Database _db;
  final ProgrammeBlobs _blobs;

  const ChapitreWriteDao({required Database db, required ProgrammeBlobs blobs})
    : _db = db,
      _blobs = blobs;

  /// Enregistre la fiche entière et la met en file. Un chapitre neuf se range
  /// en fin de programme ; le serveur le rangera aussi en fin à son arrivée.
  Future<void> saveChapitre(
    Chapitre chapitre, {
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) => _db.transaction((txn) async {
    final fiche = {
      ...ChapitreRowMapper.ficheColumns(chapitre),
      'sync_status': SyncState.pendingSync.dbValue,
      'sync_error_code': null,
      'updated_at': nowMs,
    };
    final updated = await txn.update(
      ProgrammeTables.chapitre,
      fiche,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [chapitre.id],
    );
    if (updated == 0) {
      await txn.insert(ProgrammeTables.chapitre, {
        'id': chapitre.id,
        'cours_id': chapitre.coursId,
        'ordre': await _nextOrdre(txn, chapitre.coursId),
        'server_known': 0,
        ...fiche,
      });
    }
    await enqueueProgrammeGesture(
      txn,
      entryId: ProgrammeOutbox.chapitreEntry(chapitre.id),
      type: ProgrammeOutbox.chapitreType,
      aggregateId: chapitre.id,
      payload: ChapitreFichePayload.save(chapitre).toJson(),
      schoolId: schoolId,
      nowMs: nowMs,
      authorId: authorId,
    );
  });

  /// Supprime un chapitre : sa suppression part toujours par un geste, qui
  /// remplace une fiche en attente.
  ///
  /// Jamais accusé, il quitte la tablette tout de suite avec ses enfants, sa
  /// place dans l'ordre en attente et dans les évaluations en attente (sinon
  /// elles resteraient bloquées en 409). Le geste part quand même : une fiche
  /// en vol a pu être écrite par le serveur sans que l'accusé revienne, et le
  /// chapitre redescendrait. Un serveur qui ne le connaît pas répond 404 : le
  /// geste est alors acquis.
  ///
  /// Accusé, il est masqué jusqu'à l'accusé de sa suppression ; ses notes et
  /// ressources en attente n'ont plus d'objet, le serveur les emporte.
  Future<void> deleteChapitre(
    String chapitreId, {
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) async {
    final files = await _db.transaction((txn) async {
      final row = (await txn.query(
        ProgrammeTables.chapitre,
        columns: ['cours_id', 'server_known'],
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [chapitreId],
      )).firstOrNull;
      if (row == null) return const <String>[];
      final coursId = row['cours_id'] as String;
      var files = const <String>[];
      if (row['server_known'] != 1) {
        await PendingEvaluationChapitres.detach(txn, chapitreId);
        files = await ProgrammePurge.removeChapitres(txn, [chapitreId]);
      } else {
        await txn.update(
          ProgrammeTables.chapitre,
          {
            'deleted_at': EpochIsoHelper.toIso(nowMs),
            'sync_status': SyncState.pendingSync.dbValue,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [chapitreId],
        );
        await ProgrammeOutbox.discardChildren(txn, chapitreId);
        await ProgrammeOutbox.detachFromOrdre(
          txn,
          coursId: coursId,
          chapitreId: chapitreId,
        );
      }
      await enqueueProgrammeGesture(
        txn,
        entryId: ProgrammeOutbox.chapitreEntry(chapitreId),
        type: ProgrammeOutbox.chapitreType,
        aggregateId: chapitreId,
        payload: ChapitreFichePayload.delete(
          chapitreId: chapitreId,
          coursId: coursId,
        ).toJson(),
        schoolId: schoolId,
        nowMs: nowMs,
        authorId: authorId,
      );
      return files;
    });
    await _blobs.deleteAll(files);
  }

  /// Range les chapitres dans l'ordre [chapitreIds] (liste complète du
  /// cours) et met la liste en file ; elle remplace un ordre encore en attente.
  Future<void> reorder(
    String coursId,
    List<String> chapitreIds, {
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) => _db.transaction((txn) async {
    await ProgrammeTables.applyOrdre(txn, coursId, chapitreIds, nowMs: nowMs);
    await enqueueProgrammeGesture(
      txn,
      entryId: ProgrammeOutbox.ordreEntry(coursId),
      type: ProgrammeOutbox.ordreType,
      aggregateId: coursId,
      payload: ChapitreOrdrePayload(
        coursId: coursId,
        chapitreIds: chapitreIds,
        clientUpdatedAt: EpochIsoHelper.toIso(nowMs),
      ).toJson(),
      schoolId: schoolId,
      nowMs: nowMs,
      authorId: authorId,
    );
  });

  static Future<int> _nextOrdre(DatabaseExecutor txn, String coursId) async {
    final rows = await txn.rawQuery(
      'SELECT COALESCE(MAX(ordre) + 1, 0) AS next FROM ${ProgrammeTables.chapitre} '
      'WHERE cours_id = ? AND deleted_at IS NULL',
      [coursId],
    );
    return rows.single['next'] as int;
  }
}
