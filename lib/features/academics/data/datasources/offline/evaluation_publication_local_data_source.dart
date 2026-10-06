import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_codecs.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';

/// État local des publications d'une évaluation (`evaluation.publication_json`).
///
/// Jamais écrit par l'outbox : une publication part en ligne, et c'est la
/// réponse du serveur, puis le delta, qui posent l'état ici.
class EvaluationPublicationLocalDataSource {
  final Database _db;

  const EvaluationPublicationLocalDataSource(this._db);

  static const String _table = 'evaluation';

  Future<EvaluationPublications> getPublications(String evaluationId) async {
    final rows = await _db.query(
      _table,
      columns: ['publication_json'],
      where: 'id = ?',
      whereArgs: [evaluationId],
      limit: 1,
    );
    if (rows.isEmpty) return EvaluationPublications.none;
    return SujetCodecs.publicationsFromJson(
      SujetCodecs.decodeColumn(rows.first['publication_json']),
    );
  }

  /// Pose l'état d'UNE publication ([etat] nul = retirée) sans toucher aux
  /// deux autres.
  Future<void> setPublication(
    String evaluationId,
    PublicationKind kind,
    PublicationEtat? etat,
  ) => _db.transaction((txn) async {
    final rows = await txn.query(
      _table,
      columns: ['publication_json'],
      where: 'id = ?',
      whereArgs: [evaluationId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = SujetCodecs.publicationsFromJson(
      SujetCodecs.decodeColumn(rows.first['publication_json']),
    );
    await applyPublications(
      txn,
      evaluationId: evaluationId,
      publications: current.withKind(kind, etat),
    );
  });

  /// Remplace l'état des trois publications sur [executor] (la transaction du
  /// pull, ou celle de [setPublication]).
  Future<void> applyPublications(
    DatabaseExecutor executor, {
    required String evaluationId,
    required EvaluationPublications publications,
  }) async {
    await executor.update(
      _table,
      {
        'publication_json': jsonEncode(
          SujetCodecs.publicationsToJson(publications),
        ),
      },
      where: 'id = ?',
      whereArgs: [evaluationId],
    );
  }
}
