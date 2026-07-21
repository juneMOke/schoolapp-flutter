import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/academics_cours_pull_repository_impl.dart';
import 'package:school_app_flutter/features/bootstrap/domain/repositories/bootstrap_local_repository.dart';

/// [PullHandler] des cours (référence, option B : pull par classe). Enregistré
/// sur le `PullCoordinator`.
///
/// **Self-sufficient** : résout l'`academicYearId` courant depuis le **bootstrap
/// local** (comme le handler Classe) — les classes à itérer sont ensuite lues
/// dans `ref_classrooms`. No-op propre si le bootstrap n'est pas encore chargé.
/// Ne lève pas : l'échec (`Left`) est traduit en [PullOutcome.error].
class AcademicsCoursPullHandler implements PullHandler {
  final AcademicsCoursPullRepositoryImpl _repository;
  final BootstrapLocalRepository _bootstrapRepository;
  final String _bootstrapKey;

  const AcademicsCoursPullHandler({
    required AcademicsCoursPullRepositoryImpl repository,
    required BootstrapLocalRepository bootstrapRepository,
    String bootstrapKey = AppConstants.bootstrapPayloadKey,
  }) : _repository = repository,
       _bootstrapRepository = bootstrapRepository,
       _bootstrapKey = bootstrapKey;

  static const String resourceName = kAcademicsCoursResourcePrefix;

  @override
  String get resource => resourceName;

  @override
  Future<PullOutcome> pull() async {
    final bootstrap = await _bootstrapRepository.getStoredBootstrap(
      _bootstrapKey,
    );
    final academicYearId = bootstrap.fold(
      (_) => null,
      (b) => b.academicYear.id,
    );
    if (academicYearId == null || academicYearId.isEmpty) {
      return const PullOutcome.error(
        'Année courante indisponible (bootstrap local non chargé)',
      );
    }

    final result = await _repository.syncCours(academicYearId: academicYearId);
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
