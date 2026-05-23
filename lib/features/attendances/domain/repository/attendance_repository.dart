import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceForClass({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
  });

  Future<Either<Failure, void>> recordDailyAttendance({
    required String classroomId,
    required DateTime date,
    required String academicYearId,
    required List<AttendanceUpdate> updates,
  });
}
