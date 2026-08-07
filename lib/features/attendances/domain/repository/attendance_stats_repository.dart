import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';

abstract class AttendanceStatsRepository {
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
