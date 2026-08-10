import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/attendance_pull_repository.dart';

/// [PullHandler] de la Présence — enregistré sur le `PullCoordinator`. Le jeton
/// vit dans `sync_meta` via le repository, le périmètre (école/année) est porté
/// par le JWT. Ne lève pas : l'échec (`Left`) est traduit en [PullOutcome.error].
class AttendancePullHandler implements PullHandler {
  final AttendancePullRepository _repository;

  const AttendancePullHandler(this._repository);

  @override
  String get resource => AttendancePullRepositoryImpl.resource;

  /// GET /sync/attendance — gardé sur `attendance.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.attendanceRead];

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncAttendance();
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
