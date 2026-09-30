import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';

/// Un [PullHandler] par flux du module RH (fichier et Pointage), enregistrés sur le
/// `PullCoordinator`. Ne lèvent pas : un `Left` devient un
/// [PullOutcome.error].
///
/// Chacun déclare le droit qui ouvre son flux ; c'est pourtant le plan de
/// synchronisation qui gouverne — une tablette sans `hr.pay.read` ne se voit
/// pas annoncer les contrats, et ne les tire donc jamais.
class StaffPullHandler implements PullHandler {
  @override
  final String resource;
  @override
  final List<Perm> requiredPermissions;
  final Future<Either<Failure, KeysetPullResult>> Function() _pull;

  const StaffPullHandler._(this.resource, this.requiredPermissions, this._pull);

  factory StaffPullHandler.members(StaffPullRepository repository) =>
      StaffPullHandler._(kStaffMembersResource, const [
        Perm.hrStaffRead,
      ], repository.syncMembers);

  factory StaffPullHandler.contracts(StaffPullRepository repository) =>
      StaffPullHandler._(kStaffContractsResource, const [
        Perm.hrPayRead,
      ], repository.syncContracts);

  factory StaffPullHandler.documents(StaffPullRepository repository) =>
      StaffPullHandler._(kStaffDocumentsResource, const [
        Perm.hrDocumentRead,
      ], repository.syncDocuments);

  factory StaffPullHandler.attendance(StaffPullRepository repository) =>
      StaffPullHandler._(kStaffAttendanceResource, const [
        Perm.hrAttendanceRead,
      ], repository.syncAttendance);

  factory StaffPullHandler.attendanceLocks(StaffPullRepository repository) =>
      StaffPullHandler._(kStaffAttendanceLocksResource, const [
        Perm.hrAttendanceRead,
      ], repository.syncAttendanceLocks);

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await _pull();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
