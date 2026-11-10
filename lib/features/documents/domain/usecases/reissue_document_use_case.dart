import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/editique_repository.dart';

/// La pièce à réémettre corrigée, et pourquoi.
class ReissueDocumentParams extends Equatable {
  final EditiqueDocumentType type;

  /// Référence d'archive de la pièce **en vigueur** : sans elle, rien ne la
  /// désigne au serveur.
  final String documentId;

  /// Motif d'annulation, obligatoire, imprimé nulle part mais conservé.
  final String reason;

  /// Attribuent la copie de la remplaçante.
  final String? studentId;
  final String? academicYearId;

  const ReissueDocumentParams({
    required this.type,
    required this.documentId,
    required this.reason,
    this.studentId,
    this.academicYearId,
  });

  @override
  List<Object?> get props => [
    type,
    documentId,
    reason,
    studentId,
    academicYearId,
  ];
}

/// Fait remplacer une pièce par sa version corrigée, sous le même numéro en
/// édition suivante — par exemple après une correction de niveau.
///
/// Rien ne se réémet tout seul : c'est le guichet qui le demande, quand une
/// famille réclame une pièce corrigée.
class ReissueDocumentUseCase {
  final EditiqueRepository _repository;

  const ReissueDocumentUseCase(this._repository);

  Future<Either<Failure, EditiqueDocument>> call(
    ReissueDocumentParams params,
  ) => _repository.reissue(
    type: params.type,
    documentId: params.documentId,
    reason: params.reason,
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}
