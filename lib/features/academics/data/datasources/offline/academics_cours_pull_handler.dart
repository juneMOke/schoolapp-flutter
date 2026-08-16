import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';

/// [PullHandler] des cours du prof connecté (référence, ressource unique
/// scopée enseignant — DF-K). Enregistré sur le `PullCoordinator`.
///
/// Plus de dépendance au bootstrap local / à l'année courante : le scope vient
/// du token côté serveur, pas d'un `classroomId` résolu depuis `ref_classrooms`
/// (ancienne option B, abandonnée avec le commit back `1ec6be3`). Ne lève pas :
/// l'échec (`Left`) est traduit en [PullOutcome.error].
class AcademicsCoursPullHandler implements PullHandler {
  final AcademicsCoursPullRepositoryImpl _repository;

  const AcademicsCoursPullHandler(this._repository);

  static const String resourceName = kAcademicsCoursResourcePrefix;

  @override
  String get resource => resourceName;

  /// GET /sync/academics/cours — gardé sur `academics.course.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.academicsCourseRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncCours();
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
