import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/offline/outbox_push_failure.dart';

/// Lecture d'un échec d'envoi d'un geste sur une photo.
///
/// Deux réponses ont leur conduite propre : le 409 `STUDENT_NOT_YET_SYNCED`
/// est une **attente** (l'inscription qui crée l'élève n'est pas arrivée —
/// rejouer sans consommer de tentative), le 410 `AGGREGATE_TOMBSTONED` dit
/// l'élève purgé (le geste s'efface). Tout autre 4xx — 400, 403 sans le droit,
/// 404 élève d'une autre école, 415, 422 `PHOTO_NOT_SQUARE` /
/// `PHOTO_TOO_LARGE`… — est déterministe.
class StudentPhotoPushFailure extends OutboxPushFailure {
  const StudentPhotoPushFailure._(super.status, super.detailCode, super.reason);

  static const String studentNotYetSynced = 'STUDENT_NOT_YET_SYNCED';

  factory StudentPhotoPushFailure.of(DioException e) {
    final failure = OutboxPushFailure.of(e);
    return StudentPhotoPushFailure._(
      failure.status,
      failure.detailCode,
      failure.reason,
    );
  }

  /// Le serveur n'a pas encore l'élève : son inscription est en route.
  bool get awaitsStudent => awaits(studentNotYetSynced);

  /// L'élève a été purgé côté serveur : le geste n'a plus d'objet.
  bool get isStudentGone => isGone;

  @override
  bool get isTransient => !awaitsStudent && super.isTransient;
}
