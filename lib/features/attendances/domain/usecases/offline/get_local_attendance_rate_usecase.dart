import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';

/// Taux de présence dérivé localement (AF-3).
class GetLocalAttendanceRateUseCase {
  final AttendanceOfflineRepository _repository;

  const GetLocalAttendanceRateUseCase(this._repository);

  Future<Either<Failure, LocalAttendanceRate>> call({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) => _repository.getAttendanceRate(
    classroomId: classroomId,
    date: date,
    academicYearId: academicYearId,
  );
}
