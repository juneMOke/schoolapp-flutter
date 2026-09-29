import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_lock_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_sync_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';

/// Clé `sync_meta` d'un flux, **scopée par école** : sur une tablette
/// réaffectée, un curseur nu ferait reprendre la seconde école là où la
/// première s'était arrêtée.
String staffCursorKey(String resource, String schoolId) =>
    '$resource@$schoolId';

/// Les descentes du module RH — les trois du fichier du personnel, les deux
/// du Pointage —, sur le squelette partagé [KeysetPullRunner].
class StaffPullRepositoryImpl implements StaffPullRepository {
  final StaffSyncApi _api;
  final KeysetPullRunner _runner;
  final StaffMemberDao _members;
  final StaffContractDao _contracts;
  final StaffDocumentDao _documents;
  final StaffAttendanceSyncApi _attendanceApi;
  final StaffAttendanceDao _attendance;
  final StaffAttendanceLockDao _locks;
  final CurrentUserContext _currentUser;
  final Map<String, dynamic> _requiredAuth;

  const StaffPullRepositoryImpl({
    required StaffSyncApi api,
    required KeysetPullRunner runner,
    required StaffMemberDao members,
    required StaffContractDao contracts,
    required StaffDocumentDao documents,
    required CurrentUserContext currentUser,
    required Map<String, dynamic> requiredAuth,
    required StaffAttendanceSyncApi attendanceApi,
    required StaffAttendanceDao attendance,
    required StaffAttendanceLockDao locks,
  }) : _api = api,
       _attendanceApi = attendanceApi,
       _attendance = attendance,
       _locks = locks,
       _runner = runner,
       _members = members,
       _contracts = contracts,
       _documents = documents,
       _currentUser = currentUser,
       _requiredAuth = requiredAuth;

  /// Page de 100 : le fichier d'une école tient en quelques dizaines d'agents,
  /// une descente complète en une ou deux pages.
  static const int pageLimit = 100;

  @override
  Future<Either<Failure, KeysetPullResult>> syncMembers() => _run(
    kStaffMembersResource,
    fetch: (cursor) async =>
        (await _api.pullStaffMembers(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _members.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncContracts() => _run(
    kStaffContractsResource,
    fetch: (cursor) async =>
        (await _api.pullStaffContracts(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _contracts.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncDocuments() => _run(
    kStaffDocumentsResource,
    fetch: (cursor) async =>
        (await _api.pullStaffDocuments(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _documents.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncAttendance() => _run(
    kStaffAttendanceResource,
    fetch: (cursor) async => (await _attendanceApi.pullAttendance(
      _requiredAuth,
      cursor,
      pageLimit,
    )).data,
    apply: (items, schoolId, nowMs) =>
        _attendance.applyPulled(items, schoolId: schoolId, nowMs: nowMs),
  );

  @override
  Future<Either<Failure, KeysetPullResult>> syncAttendanceLocks() => _run(
    kStaffAttendanceLocksResource,
    fetch: (cursor) async =>
        (await _attendanceApi.pullLocks(_requiredAuth, cursor, pageLimit)).data,
    apply: (items, schoolId, nowMs) =>
        _locks.applyServer(items, schoolId: schoolId, nowMs: nowMs),
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
