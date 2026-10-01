import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';

// Les cas d'usage du registre d'appel d'une classe (Présences des élèves v2).

class LoadClassPresenceDayUseCase {
  final ClassPresenceRepository _repository;

  const LoadClassPresenceDayUseCase(this._repository);

  Future<Either<Failure, ClassPresenceDay>> call(ClassDayKey key) =>
      _repository.loadDay(key);
}

class SaveClassPresenceMarksUseCase {
  final ClassPresenceRepository _repository;

  const SaveClassPresenceMarksUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    ClassDayKey key,
    Map<String, PresenceMark<AbsenceReason>> marks,
  ) => _repository.saveMarks(key, marks);
}

/// Valide l'appel, ou renvoie un appel validé dont une justification a
/// changé : dans les deux cas, la classe entière part.
class ValidateClassPresenceDayUseCase {
  final ClassPresenceRepository _repository;

  const ValidateClassPresenceDayUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    ClassDayKey key,
    List<ClassPresenceLine> lines,
  ) => _repository.validateDay(key, lines);
}

class ReopenClassPresenceDayUseCase {
  final ClassPresenceRepository _repository;

  const ReopenClassPresenceDayUseCase(this._repository);

  Future<Either<Failure, Unit>> call(ClassDayKey key) =>
      _repository.reopenDay(key);
}

class RetryClassPresenceDayUseCase {
  final ClassPresenceRepository _repository;

  const RetryClassPresenceDayUseCase(this._repository);

  Future<Either<Failure, Unit>> call(ClassDayKey key) =>
      _repository.retryDay(key);
}

class LoadClassPresenceMonthUseCase {
  final ClassPresenceRepository _repository;

  const LoadClassPresenceMonthUseCase(this._repository);

  Future<Either<Failure, ClassPresenceMonth>> call(ClassMonthKey key) =>
      _repository.loadMonth(key);
}

class CloseClassPresenceMonthUseCase {
  final ClassPresenceRepository _repository;

  const CloseClassPresenceMonthUseCase(this._repository);

  Future<Either<Failure, Unit>> call(ClassMonthKey key) =>
      _repository.closeMonth(key);
}
