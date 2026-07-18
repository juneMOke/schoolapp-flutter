import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_offline_repository.dart';

/// Statistiques d'assiduité d'un élève sur une période, calculées en local
/// (AF-3, §5). La date de référence est fournie par l'appelant (l'UI) — pas
/// d'horloge implicite dans le domaine.
class GetStudentAttendanceStatsUseCase {
  final AttendanceOfflineRepository _repository;

  const GetStudentAttendanceStatsUseCase(this._repository);

  Future<Either<Failure, StudentAttendanceStats>> call({
    required String studentId,
    required String classroomId,
    required String academicYearId,
    required StatsPeriod period,
    required DateTime reference,
  }) => _repository.getStudentAttendanceStats(
    studentId: studentId,
    classroomId: classroomId,
    academicYearId: academicYearId,
    period: period,
    reference: reference,
  );
}
