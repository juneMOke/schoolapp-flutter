import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_copie_log_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_publication_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';

/// Applique des évaluations vues du serveur (`EvaluationSyncView`) — le delta
/// du pull, et la réponse des écritures du sujet et du journal.
///
/// L'évaluation d'abord (une ligne en attente gagne), puis, par évaluation et
/// dans une transaction : le sujet (un brouillon local en attente ou refusé
/// gagne), le journal (union), l'état des publications (vérité serveur).
/// Tout est idempotent : un rejeu après interruption ne change rien.
class EvaluationViewApplier {
  final Database _db;
  final AcademicsLocalDataSource _academics;
  final EvaluationSujetLocalDataSource _sujets;
  final EvaluationCopieLogLocalDataSource _copieLog;
  final EvaluationPublicationLocalDataSource _publications;

  const EvaluationViewApplier({
    required Database db,
    required AcademicsLocalDataSource academics,
    required EvaluationSujetLocalDataSource sujets,
    required EvaluationCopieLogLocalDataSource copieLog,
    required EvaluationPublicationLocalDataSource publications,
  }) : _db = db,
       _academics = academics,
       _sujets = sujets,
       _copieLog = copieLog,
       _publications = publications;

  /// Toutes les tables sur la même base — les DAO sont des enveloppes sans
  /// état.
  factory EvaluationViewApplier.on(Database db) => EvaluationViewApplier(
    db: db,
    academics: AcademicsLocalDataSource(db),
    sujets: EvaluationSujetLocalDataSource(db),
    copieLog: EvaluationCopieLogLocalDataSource(db),
    publications: EvaluationPublicationLocalDataSource(db),
  );

  /// Renvoie le nombre d'évaluations appliquées.
  Future<int> apply(List<EvaluationDeltaDto> views, int syncedAt) async {
    final applied = await _academics.applyPulledEvaluations([
      for (final v in views) v.toLocalRow(syncedAt),
    ]);
    for (final view in views) {
      await _db.transaction((txn) async {
        await _sujets.applyPulledSujet(
          txn,
          evaluationId: view.id,
          sujet: view.toSujetRow(),
        );
        await _copieLog.applyPulled(txn, view.toCopieLogRows());
        await _publications.applyPublications(
          txn,
          evaluationId: view.id,
          publications: view.publications,
        );
      });
    }
    return applied;
  }
}
