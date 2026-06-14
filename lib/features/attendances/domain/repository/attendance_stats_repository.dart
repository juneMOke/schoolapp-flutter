import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';

abstract class AttendanceStatsRepository {
  /// Resume de presence d'un eleve sur une fenetre.
  ///
  /// [month] (ancre `YYYY-MM`) est requis quand [period] vaut
  /// [StatsPeriod.month] ; [week] (ancre `YYYY-MM-DD`) quand elle vaut
  /// [StatsPeriod.week].
  Future<Either<Failure, StudentAttendanceSummary>>
  getStudentAttendanceSummary({
    required String studentId,
    StatsPeriod period = StatsPeriod.year,
    String? month,
    String? week,
  });

  /// Tableau de bord de presence a l'echelle de l'ecole pour une periode.
  ///
  /// [month] (ancre `YYYY-MM`) est requis quand [period] vaut
  /// [StatsPeriod.month] ; [week] (ancre `YYYY-Www`) quand elle vaut
  /// [StatsPeriod.week].
  Future<Either<Failure, AttendanceOverview>> getAttendanceOverview({
    StatsPeriod period = StatsPeriod.year,
    String? month,
    String? week,
  });
}
