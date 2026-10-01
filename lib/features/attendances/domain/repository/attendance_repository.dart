import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceForClass({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  });
}
