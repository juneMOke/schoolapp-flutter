import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';

/// Ressource de pull des clôtures de mois de l'appel.
const String kAttendanceClosuresResource = 'attendance_closures';

/// Descend les clôtures de mois (`GET /sync/attendance-closures`, keyset) —
/// celles des autres tablettes comprises, pour que le mois se fige partout.
class AttendanceClosurePullHandler implements PullHandler {
  final AttendanceClosureApi api;
  final AttendanceClosureLocalDataSource closures;
  final KeysetPullRunner runner;
  final Map<String, dynamic> requiredAuth;

  const AttendanceClosurePullHandler({
    required this.api,
    required this.closures,
    required this.runner,
    required this.requiredAuth,
  });

  static const int pageLimit = 100;

  @override
  String get resource => kAttendanceClosuresResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.attendanceRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await runner.run(
      cursorKey: kAttendanceClosuresResource,
      label: kAttendanceClosuresResource,
      fetch: (cursor) async =>
          (await api.pullClosures(requiredAuth, cursor, pageLimit)).data,
      apply: (items, _) => closures.applyPulled(items),
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
