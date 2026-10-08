import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_puller.dart';

/// [PullHandler] du flux `enrollment.suspensions`, accordé par
/// `enrollment.read`.
class EnrollmentSuspensionPullHandler implements PullHandler {
  final EnrollmentSuspensionPuller _puller;

  const EnrollmentSuspensionPullHandler(this._puller);

  @override
  String get resource => kEnrollmentSuspensionsResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.enrollmentRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    final result = await _puller.pull();
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
