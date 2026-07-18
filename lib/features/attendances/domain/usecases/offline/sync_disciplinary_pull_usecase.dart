import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_pull_outcome.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_pull_repository.dart';

/// Déclenche le pull keyset de la Discipline (hydratation au montage du
/// FeatureScope). Le second déclencheur — retour online — passe par le
/// `PullCoordinator` (`DisciplinaryPullHandler`). Les DEUX sont nécessaires : une
/// tablette démarrée déjà connectée ne tirerait jamais sur le seul signal online.
class SyncDisciplinaryPullUseCase {
  final DisciplinaryPullRepository _repository;

  const SyncDisciplinaryPullUseCase(this._repository);

  Future<Either<Failure, DisciplinaryPullOutcome>> call() =>
      _repository.syncDisciplinaryCases();
}
