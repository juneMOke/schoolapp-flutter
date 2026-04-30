import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_repository.dart';

class UpdateAttendanceUseCase {
  final AttendanceRepository _repository;

  const UpdateAttendanceUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
    required List<AttendanceUpdate> updates,
  }) => _repository.recordDailyAttendance(
    classroomId: classroomId,
    date: date,
    academicYearId: academicYearId,
    updates: updates,
  );
}
