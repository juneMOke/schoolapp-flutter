import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/justification/attendance_justification_local_data_source.dart';

/// Ressource de pull des justifications d'absence des parents.
const String kAttendanceJustificationsResource = 'attendance_justifications';

/// Descend les justifications d'absence des parents
/// (`GET /sync/attendance-justifications`, keyset).
///
/// Sous `attendance.amend` **seul**, et jamais entraîné : un profil sans ce
/// droit recevrait un 403. Tiré après les classes, les rosters et l'appel,
/// dont il dépend (ordre d'enregistrement en DI).
class AttendanceJustificationPullHandler implements PullHandler {
  final AttendanceJustificationApi api;
  final AttendanceJustificationLocalDataSource justifications;
  final KeysetPullRunner runner;
  final Map<String, dynamic> requiredAuth;

  const AttendanceJustificationPullHandler({
    required this.api,
    required this.justifications,
    required this.runner,
    required this.requiredAuth,
  });

  static const int pageLimit = 100;

  @override
  String get resource => kAttendanceJustificationsResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.attendanceAmend];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await runner.run(
      cursorKey: kAttendanceJustificationsResource,
      label: kAttendanceJustificationsResource,
      fetch: (cursor) async =>
          (await api.pullJustifications(requiredAuth, cursor, pageLimit)).data,
      apply: (items, _) => justifications.applyPulled(items),
    );
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
