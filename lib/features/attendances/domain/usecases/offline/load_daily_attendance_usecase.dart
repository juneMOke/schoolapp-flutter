import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';

/// Charge la liste d'appel d'un jour (AF-1) : roster ACTIVE présent par défaut,
/// écrasé par les absences/retards locaux.
class LoadDailyAttendanceUseCase {
  final AttendanceOfflineRepository _repository;

  const LoadDailyAttendanceUseCase(this._repository);

  Future<Either<Failure, List<AttendanceRecord>>> call({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) => _repository.loadDailyAttendance(
    classroomId: classroomId,
    date: date,
    academicYearId: academicYearId,
  );
}
