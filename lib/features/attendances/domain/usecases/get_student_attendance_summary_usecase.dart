import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_stats_repository.dart';

class GetStudentAttendanceSummaryUseCase {
  final AttendanceStatsRepository _repository;

  const GetStudentAttendanceSummaryUseCase(this._repository);

  Future<Either<Failure, StudentAttendanceSummary>> call({
    required String studentId,
    StatsPeriod period = StatsPeriod.year,
    String? month,
    String? week,
  }) {
    // Garde-fou : les ancres sont requises selon la periode (contrat backend),
    // on evite un aller-retour reseau voue a un 400.
    if (period == StatsPeriod.month &&
        (month == null || month.trim().isEmpty)) {
      return Future.value(
        const Left(
          ValidationFailure('month anchor is required when period=month'),
        ),
      );
    }
    if (period == StatsPeriod.week && (week == null || week.trim().isEmpty)) {
      return Future.value(
        const Left(
          ValidationFailure('week anchor is required when period=week'),
        ),
      );
    }

    return _repository.getStudentAttendanceSummary(
      studentId: studentId,
      period: period,
      month: month,
      week: week,
    );
  }
}
