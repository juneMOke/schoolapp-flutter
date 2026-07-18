import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/daily_attendance.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';

/// Charge l'appel d'un jour (AF-1) : les **3 états** (appel non fait / présent /
/// absent), roster ACTIVE présent par défaut écrasé par les absences locales.
class LoadDailyAttendanceUseCase {
  final AttendanceOfflineRepository _repository;

  const LoadDailyAttendanceUseCase(this._repository);

  Future<Either<Failure, DailyAttendance>> call({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) => _repository.loadDailyAttendance(
    classroomId: classroomId,
    date: date,
    academicYearId: academicYearId,
  );
}
