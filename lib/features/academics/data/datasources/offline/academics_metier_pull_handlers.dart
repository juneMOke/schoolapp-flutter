import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_metier_pull_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/offline/academics_delta_pull_outcome.dart';

/// [PullHandler] d'un flux scopé cours (itéré par cours, curseur propre) :
/// évaluations, notes, chapitres. Enregistré sur le `PullCoordinator`. Ne
/// lève pas.
class CoursScopedPullHandler implements PullHandler {
  @override
  final String resource;

  @override
  final List<Perm> requiredPermissions;

  final Future<Either<Failure, AcademicsDeltaPullOutcome>> Function() _pull;

  const CoursScopedPullHandler({
    required this.resource,
    required this.requiredPermissions,
    required Future<Either<Failure, AcademicsDeltaPullOutcome>> Function() pull,
  }) : _pull = pull;

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await _pull();
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

/// Les évaluations (GET /sync/academics/evaluations — `academics.grade.read`).
class EvaluationsPullHandler extends CoursScopedPullHandler {
  EvaluationsPullHandler(AcademicsMetierPullRepositoryImpl repository)
    : super(
        resource: kAcademicsEvaluationsResourcePrefix,
        requiredPermissions: const [Perm.academicsGradeRead],
        pull: repository.syncEvaluations,
      );
}

/// Les notes (GET /sync/academics/notes — `academics.grade.read`), curseur
/// indépendant des évaluations.
class NotesPullHandler extends CoursScopedPullHandler {
  NotesPullHandler(AcademicsMetierPullRepositoryImpl repository)
    : super(
        resource: kAcademicsNotesResourcePrefix,
        requiredPermissions: const [Perm.academicsGradeRead],
        pull: repository.syncNotes,
      );
}
