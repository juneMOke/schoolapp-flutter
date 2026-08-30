import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student/domain/repositories/parent_repository.dart';

/// Désigne le tuteur à appeler en urgence pour un élève, **après** que son
/// dossier a été finalisé — la seule écriture qui reste ouverte sur un dossier
/// par ailleurs en consultation.
///
/// [parentId] à `null` retire la désignation sans en poser d'autre : « aucun
/// contact » est un état légitime, et il doit pouvoir se dire.
class SetEmergencyContactUseCase {
  final ParentRepository _repository;

  const SetEmergencyContactUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String studentId,
    required String? parentId,
  }) =>
      _repository.setEmergencyContact(studentId: studentId, parentId: parentId);
}
