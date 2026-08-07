import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/disciplinary_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_pull_repository.dart';

/// [PullHandler] de la Discipline — enregistré sur le `PullCoordinator`. Le jeton
/// vit dans `sync_meta` via le repository, le périmètre (école/année) et la
/// visibilité par rôle sont portés par le JWT. Ne lève pas : l'échec (`Left`) est
/// traduit en [PullOutcome.error].
class DisciplinaryPullHandler implements PullHandler {
  final DisciplinaryPullRepository _repository;

  const DisciplinaryPullHandler(this._repository);

  @override
  String get resource => DisciplinaryPullRepositoryImpl.resource;

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncDisciplinaryCases();
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
