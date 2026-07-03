import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';

/// Charge la grille d'emploi du temps d'une classe (conseil pédagogique).
///
/// Deux paramètres ⇒ objet [GetClassroomGridParams] dédié (convention projet).
class GetClassroomGridUseCase {
  final ScheduleRepository _repository;

  const GetClassroomGridUseCase(this._repository);

  Future<Either<Failure, WeeklyTimetable>> call(
    GetClassroomGridParams params,
  ) => _repository.getClassroomGrid(params.classroomId, params.academicYearId);
}

class GetClassroomGridParams extends Equatable {
  final String classroomId;
  final String academicYearId;

  const GetClassroomGridParams({
    required this.classroomId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [classroomId, academicYearId];
}
