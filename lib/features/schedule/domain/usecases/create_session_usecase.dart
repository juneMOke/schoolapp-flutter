import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

/// Place un cours à l'emploi du temps et renvoie la séance créée.
class CreateSessionUseCase {
  final ScheduleRepository _repository;

  const CreateSessionUseCase(this._repository);

  Future<Either<Failure, Session>> call(CreateSessionRequest request) =>
      _repository.createSession(request);
}
