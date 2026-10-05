import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_puller.dart';

/// [PullHandler] du flux `student.photos`, accordé par `student.read`.
class StudentPhotoPullHandler implements PullHandler {
  final StudentPhotoPuller _puller;

  const StudentPhotoPullHandler(this._puller);

  @override
  String get resource => kStudentPhotosResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.studentRead];

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
