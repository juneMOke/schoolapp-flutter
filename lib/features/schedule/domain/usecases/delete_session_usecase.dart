import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

/// Retire une séance de l'emploi du temps. Renvoie `Right(unit)` sur succès.
class DeleteSessionUseCase {
  final ScheduleRepository _repository;

  const DeleteSessionUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String sessionId) =>
      _repository.deleteSession(sessionId);
}
