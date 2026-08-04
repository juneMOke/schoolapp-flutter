import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Le serveur connaît-il déjà cet élève ?
///
/// Garde des pièces d'éditique scopées élève (note de perception, relevé de
/// compte, quitus) : elles prennent le `studentId` dans le chemin de l'URL, et
/// un élève saisi hors ligne porte un uuid **client** que le serveur n'a pas
/// encore honoré — l'appel répondrait 404.
///
/// La réponse est **fail-closed** de bout en bout : toute incertitude (échec de
/// lecture locale comprise) doit être traitée comme « non » par l'appelant.
class IsStudentKnownToServerUseCase {
  final EnrollmentOfflineRepository _repository;

  const IsStudentKnownToServerUseCase(this._repository);

  Future<Either<Failure, bool>> call(String studentId) =>
      _repository.isStudentKnownToServer(studentId);
}
