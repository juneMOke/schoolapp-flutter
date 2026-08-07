import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_freshness.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_pull_repository.dart';

/// Fraîcheur locale de la Discipline (ADR-002) — sans réseau, pour la pastille
/// « Mon poste » / « À jour ».
class GetDisciplinaryFreshnessOfflineUseCase {
  final DisciplinaryPullRepository _repository;

  const GetDisciplinaryFreshnessOfflineUseCase(this._repository);

  Future<DisciplinaryFreshness> call() => _repository.freshness();
}
