import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

/// Étape Résumé du wizard : confirme le brouillon (DRAFT → PENDING_SYNC) et
/// déclenche le flush opportuniste.
class FinalizeDraftUseCase {
  final EnrollmentOfflineRepository _repository;

  const FinalizeDraftUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String enrollmentId,
    bool emitDocument = true,
  }) => _repository.finalizeDraft(
    enrollmentId: enrollmentId,
    emitDocument: emitDocument,
  );
}
