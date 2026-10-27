import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_report.dart';
import 'package:school_app_flutter/features/hr_presence/domain/repositories/hr_attendance_stats_repository.dart';

class GetHrAttendanceDashboardUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceDashboardUseCase(this._repository);

  Future<Either<Failure, HrAttendanceDashboard>> call(DashboardWindow window) =>
      _repository.dashboard(window);
}

class GetHrAttendanceAgentMonthUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceAgentMonthUseCase(this._repository);

  Future<Either<Failure, HrAttendanceAgentMonth>> call(
    String staffMemberId, {
    required String month,
  }) => _repository.agentMonth(staffMemberId, month: month);
}

class GetHrAttendanceAgentYearUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceAgentYearUseCase(this._repository);

  Future<Either<Failure, HrAttendanceAgentYear>> call(String staffMemberId) =>
      _repository.agentYear(staffMemberId);
}

class GetHrAttendanceProfilesUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceProfilesUseCase(this._repository);

  Future<Either<Failure, HrAttendanceProfiles>> call(HrProfileScope scope) =>
      _repository.profiles(scope);
}

class GetHrAttendanceRecapUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceRecapUseCase(this._repository);

  Future<Either<Failure, HrAttendanceRecap>> call(String month) =>
      _repository.recap(month);
}

class GetHrAttendanceReportUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceReportUseCase(this._repository);

  Future<Either<Failure, HrAttendanceReport>> call(
    DashboardWindow window, {
    String search = '',
  }) => _repository.report(window, search: search);
}

class GetHrAttendanceProfilesReportUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceProfilesReportUseCase(this._repository);

  Future<Either<Failure, HrAttendanceReport>> call(
    HrProfileScope scope, {
    String search = '',
    StaffCategory? category,
    PresenceProfile? profile,
  }) => _repository.profilesReport(
    scope,
    search: search,
    category: category,
    profile: profile,
  );
}

class GetHrAttendanceAgentSheetUseCase {
  final HrAttendanceStatsRepository _repository;

  const GetHrAttendanceAgentSheetUseCase(this._repository);

  /// [month] `null` : l'année scolaire courante.
  Future<Either<Failure, HrAttendanceReport>> call(
    String staffMemberId, {
    String? month,
  }) => _repository.agentSheet(staffMemberId, month: month);
}
