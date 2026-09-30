import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/features/payroll/data/local/attendance_summary_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_disbursement_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/salary_advance_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/staff_pay_profile_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_sync_api.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_pull_repository.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_pull_repository_impl.dart';

/// Les descentes de la Paie, sur le squelette partagé [KeysetPullRunner] ;
/// curseurs scopés par école comme ceux du fichier du personnel.
class PayrollPullRepositoryImpl implements PayrollPullRepository {
  final PayrollSyncApi _api;
  final KeysetPullRunner _runner;
  final PayrollDao _payrolls;
  final StaffPayProfileDao _profiles;
  final AttendanceSummaryDao _summaries;
  final SalaryAdvanceDao _advances;
  final PayrollDisbursementDao _disbursements;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const PayrollPullRepositoryImpl({
    required PayrollSyncApi api,
    required KeysetPullRunner runner,
    required PayrollDao payrolls,
    required StaffPayProfileDao profiles,
    required AttendanceSummaryDao summaries,
    required SalaryAdvanceDao advances,
    required PayrollDisbursementDao disbursements,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
  }) : _api = api,
       _runner = runner,
       _payrolls = payrolls,
       _profiles = profiles,
       _summaries = summaries,
       _advances = advances,
       _disbursements = disbursements,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  /// Page de 50 : une paie porte ses lignes figées, une par agent.
  static const int pageLimit = 50;

  @override
  Future<Either<Failure, KeysetPullResult>> syncPayrolls() => _run(
    kPayrollsResource,
    fetch: (cursor) async =>
        (await _api.pullPayrolls(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _payrolls.apply(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncProfiles() => _run(
    kStaffPayProfilesResource,
    fetch: (cursor) async =>
        (await _api.pullProfiles(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _profiles.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncAttendanceSummaries() => _run(
    kStaffAttendanceSummariesResource,
    fetch: (cursor) async =>
        (await _api.pullSummaries(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _summaries.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncAdvances() => _run(
    kSalaryAdvancesResource,
    fetch: (cursor) async =>
        (await _api.pullAdvances(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _advances.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncDisbursements() => _run(
    kPayrollDisbursementsResource,
    fetch: (cursor) async =>
        (await _api.pullDisbursements(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _disbursements.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  Future<Either<Failure, KeysetPullResult>> _run<I>(
    String resource, {
    required KeysetPageFetcher<I> fetch,
    required Future<int> Function(List<I> items, String schoolId, int nowMs)
    apply,
  }) async {
    final schoolId = _currentUser.schoolId;
    if (schoolId == null || schoolId.isEmpty) {
      return const Left(ServerFailure('Aucune école courante'));
    }
    return _runner.run<I>(
      cursorKey: staffCursorKey(resource, schoolId),
      label: resource,
      fetch: fetch,
      apply: (items, nowMs) => apply(items, schoolId, nowMs),
    );
  }
}
