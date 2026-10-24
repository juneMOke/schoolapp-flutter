import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_list_report.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/repositories/hr_staff_dashboard_repository.dart';

class GetHrStaffStatsUseCase {
  final HrStaffDashboardRepository _repository;

  const GetHrStaffStatsUseCase(this._repository);

  Future<Either<Failure, HrStaffStats>> call() => _repository.stats();
}

class GetHrStaffMembersUseCase {
  final HrStaffDashboardRepository _repository;

  const GetHrStaffMembersUseCase(this._repository);

  Future<Either<Failure, HrStaffMembersPage>> call(
    HrRosterQuery query, {
    required int page,
  }) => _repository.members(query, page: page);
}

class GetHrStaffListReportUseCase {
  final HrStaffDashboardRepository _repository;

  const GetHrStaffListReportUseCase(this._repository);

  Future<Either<Failure, HrStaffListReport>> call(HrRosterQuery query) =>
      _repository.report(query);
}
