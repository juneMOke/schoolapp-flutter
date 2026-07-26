import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_pull_outcome.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_pull_repository.dart';

/// Déclenche le pull keyset de la Discipline (hydratation au montage du
/// FeatureScope). Le second déclencheur — retour online — passe par le
/// `PullCoordinator` (`DisciplinaryPullHandler`). Les DEUX sont nécessaires : une
/// tablette démarrée déjà connectée ne tirerait jamais sur le seul signal online.
///
/// **Gate connectivité** : ce déclencheur mount-time contourne le
/// `PullCoordinator` et son propre gate — sans revérifier `ConnectivityService`
/// ici, une tablette hors-ligne taperait quand même le réseau à chaque montage
/// (même raisonnement que `SyncFinancePullsUseCase` / `SyncClassroomsUseCase`).
class SyncDisciplinaryPullUseCase {
  final DisciplinaryPullRepository _repository;
  final ConnectivityService _connectivity;

  const SyncDisciplinaryPullUseCase(this._repository, this._connectivity);

  Future<Either<Failure, DisciplinaryPullOutcome>> call() async {
    if (!await _connectivity.isOnline()) {
      return const Left(NetworkFailure('Offline: disciplinary sync skipped'));
    }
    return _repository.syncDisciplinaryCases();
  }
}
