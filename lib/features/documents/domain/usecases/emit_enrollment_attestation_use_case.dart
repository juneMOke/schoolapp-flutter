import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';

/// Émet l'attestation d'inscription (AI) d'un dossier.
///
/// Pièce archivée et idempotente : réémettre re-sert les mêmes octets sous le
/// même numéro. Le serveur la scelle déjà automatiquement au push d'inscription
/// — cet appel sert donc surtout à la **récupérer**.
class EmitEnrollmentAttestationUseCase {
  final EditiqueRepository _repository;

  const EmitEnrollmentAttestationUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    EmitEnrollmentAttestationParams params,
  ) => _repository.emitEnrollmentAttestation(
    enrollmentId: params.enrollmentId,
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}

class EmitEnrollmentAttestationParams extends Equatable {
  /// Identifiant **serveur** du dossier. Un dossier encore local (brouillon ou
  /// en attente de synchro) porte un uuid client inconnu du serveur, et un
  /// candidat de réinscription n'en a aucun : les deux produisent un 404.
  final String enrollmentId;

  /// Attribuent la **copie locale**, pas l'appel serveur : le serveur ne
  /// connaît que le dossier. Sans eux, la pièce est mise en cache sans élève,
  /// et le catalogue — qui lit « les pièces de cet élève » — ne la retrouve
  /// jamais.
  final String? studentId;
  final String? academicYearId;

  const EmitEnrollmentAttestationParams({
    required this.enrollmentId,
    this.studentId,
    this.academicYearId,
  });

  @override
  List<Object?> get props => [enrollmentId, studentId, academicYearId];
}
