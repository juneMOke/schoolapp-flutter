import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';

/// Ce qui désigne une pièce déjà scellée.
///
/// Deux identifiants, dont un seul est exigé, et ils ne servent pas à la même
/// chose : [documentId] est la référence d'archive du serveur — la seule qui
/// permette un re-téléchargement —, [documentNumber] est le numéro imprimé sur
/// la pièce, unique par école, qui suffit à interroger le cache local.
class RestituteDocumentParams extends Equatable {
  final EditiqueDocumentType type;
  final String? documentId;
  final String? documentNumber;

  /// Attribuent la copie qu'un re-téléchargement déposerait. Les omettre
  /// recréerait une entrée orpheline là où il y en avait une attribuée.
  final String? studentId;
  final String? academicYearId;

  const RestituteDocumentParams({
    required this.type,
    this.documentId,
    this.documentNumber,
    this.studentId,
    this.academicYearId,
  });

  @override
  List<Object?> get props => [
    type,
    documentId,
    documentNumber,
    studentId,
    academicYearId,
  ];
}

/// Ressort une pièce **archivée** déjà scellée : la copie locale d'abord, le
/// re-téléchargement ensuite (ADR-012 D-1).
///
/// À ne jamais confondre avec une émission. Restituer ne produit rien, ne
/// consomme aucun numéro de séquence, et se rejoue librement — c'est ce qui
/// permet de l'offrir hors ligne, et ce qui interdit de l'utiliser pour un
/// relevé ou un quitus, que le serveur recalcule à chaque demande.
class RestituteDocumentUseCase {
  final EditiqueRepository _repository;

  const RestituteDocumentUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    RestituteDocumentParams params,
  ) => _repository.restitute(
    type: params.type,
    documentId: params.documentId,
    documentNumber: params.documentNumber,
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}
