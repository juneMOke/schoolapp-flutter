import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';

/// Les ressources de descente de la Paie (`PullHandler.resource`).
const String kPayrollsResource = 'payrolls';
const String kStaffPayProfilesResource = 'staff_pay_profiles';
const String kStaffAttendanceSummariesResource = 'staff_attendance_summaries';
const String kSalaryAdvancesResource = 'salary_advances';
const String kPayrollDisbursementsResource = 'payroll_disbursements';

/// Ce que l'écran de la paie lit : les agents et leurs contrats, puis les
/// cinq flux de la paie.
const Set<String> kPayrollScreenResources = {
  kStaffMembersResource,
  kStaffContractsResource,
  kPayrollsResource,
  kStaffPayProfilesResource,
  kStaffAttendanceSummariesResource,
  kSalaryAdvancesResource,
  kPayrollDisbursementsResource,
};

/// Les cinq descentes de la Paie, toutes sous `hr.pay.read`.
abstract class PayrollPullRepository {
  Future<Either<Failure, KeysetPullResult>> syncPayrolls();
  Future<Either<Failure, KeysetPullResult>> syncProfiles();
  Future<Either<Failure, KeysetPullResult>> syncAttendanceSummaries();
  Future<Either<Failure, KeysetPullResult>> syncAdvances();
  Future<Either<Failure, KeysetPullResult>> syncDisbursements();
}
