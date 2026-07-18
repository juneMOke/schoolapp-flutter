import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';

/// CF4 — Transfert d'élève **OFFLINE** (ADR-004 amendé). Un seul chemin
/// d'écriture : l'événement local + outbox (flush opportuniste quand connecté).
/// Retourne l'`id` du transfert créé.
class RecordClassroomTransferUseCase {
  final ClassroomOfflineRepository _repository;

  const RecordClassroomTransferUseCase(this._repository);

  Future<Either<Failure, String>> call(RecordClassroomTransferDraft draft) =>
      _repository.recordTransfer(draft);
}
