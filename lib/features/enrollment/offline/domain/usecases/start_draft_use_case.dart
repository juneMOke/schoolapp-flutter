import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Démarre un brouillon de wizard : renvoie les ids client figés (aucune
/// écriture DB à ce stade).
class StartDraftUseCase {
  final EnrollmentOfflineRepository _repository;

  const StartDraftUseCase(this._repository);

  DraftIds call({String? existingStudentId}) =>
      _repository.startDraft(existingStudentId: existingStudentId);
}
