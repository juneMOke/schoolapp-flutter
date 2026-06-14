import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_overview.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_stats_repository.dart';

class GetAttendanceOverviewUseCase {
  final AttendanceStatsRepository _repository;

  const GetAttendanceOverviewUseCase(this._repository);

  /// Tableau de bord de presence pour une periode.
  ///
  /// [month] (`YYYY-MM`) et [week] (`YYYY-Www`) sont des ancres OPTIONNELLES :
  /// le backend retombe sur la periode courante quand elles sont absentes
  /// (contrat de l'endpoint overview, aligne sur finance/enrollment-stats).
  /// On ne garde donc pas de garde-fou : les anneres sont transmises telles
  /// quelles (le selecteur de periode du dashboard n'envoie que la periode).
  Future<Either<Failure, AttendanceOverview>> call({
    StatsPeriod period = StatsPeriod.year,
    String? month,
    String? week,
  }) => _repository.getAttendanceOverview(
    period: period,
    month: month,
    week: week,
  );
}
