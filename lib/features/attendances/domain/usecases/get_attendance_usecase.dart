import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_repository.dart';

class GetAttendanceUseCase {
  final AttendanceRepository _repository;

  const GetAttendanceUseCase(this._repository);

  Future<Either<Failure, List<AttendanceRecord>>> call({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  }) => _repository.getAttendanceForClass(
    classroomId: classroomId,
    date: date,
    academicYearId: academicYearId,
  );
}
