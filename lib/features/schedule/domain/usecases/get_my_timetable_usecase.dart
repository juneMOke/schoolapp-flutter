import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

/// Charge l'emploi du temps de l'enseignant connecté pour l'année scolaire
/// [academicYearId]. L'enseignant est résolu côté backend depuis le JWT.
class GetMyTimetableUseCase {
  final ScheduleRepository _repository;

  const GetMyTimetableUseCase(this._repository);

  Future<Either<Failure, WeeklyTimetable>> call(String academicYearId) =>
      _repository.getMyTimetable(academicYearId);
}
