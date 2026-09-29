import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_content.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_document_repository.dart';

/// Le référentiel des pièces et celles versées pour un agent.
class LoadStaffDossierUseCase {
  final StaffDocumentRepository _repository;

  const LoadStaffDossierUseCase(this._repository);

  Future<Either<Failure, StaffDossierSnapshot>> call(String staffMemberId) =>
      _repository.dossierOf(staffMemberId);
}

/// Verse une pièce et la met en file d'envoi.
class AddStaffDocumentUseCase {
  final StaffDocumentRepository _repository;

  const AddStaffDocumentUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    String staffMemberId,
    String rawCode,
    CapturedDocument document,
  ) => _repository.addDocument(staffMemberId, rawCode, document);
}

/// Les octets d'une pièce, pour la montrer.
class OpenStaffDocumentUseCase {
  final StaffDocumentRepository _repository;

  const OpenStaffDocumentUseCase(this._repository);

  Future<Either<Failure, StaffDocumentContent>> call(StaffDocument document) =>
      _repository.open(document);
}
