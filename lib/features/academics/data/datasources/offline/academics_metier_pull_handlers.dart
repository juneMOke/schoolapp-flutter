import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';

/// [PullHandler] des évaluations (référence des évaluations serveur, itéré par
/// cours). Enregistré sur le `PullCoordinator`. Ne lève pas.
class EvaluationsPullHandler implements PullHandler {
  final AcademicsMetierPullRepositoryImpl _repository;

  const EvaluationsPullHandler(this._repository);

  @override
  String get resource => kAcademicsEvaluationsResourcePrefix;

  /// GET /sync/academics/evaluations — gardé sur `academics.grade.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.academicsGradeRead];

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncEvaluations();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}

/// [PullHandler] des notes (itéré par cours, curseur indépendant des évaluations).
class NotesPullHandler implements PullHandler {
  final AcademicsMetierPullRepositoryImpl _repository;

  const NotesPullHandler(this._repository);

  @override
  String get resource => kAcademicsNotesResourcePrefix;

  /// GET /sync/academics/notes — gardé sur `academics.grade.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.academicsGradeRead];

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncNotes();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
