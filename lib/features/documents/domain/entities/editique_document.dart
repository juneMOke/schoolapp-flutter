import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';

/// Une pièce d'éditique telle que le serveur vient de la rendre.
///
/// Purement en mémoire : rien n'est écrit sur le disque ni dans la base
/// chiffrée à ce stade. C'est la couche présentation (lot suivant) qui décidera
/// de l'afficher, de l'imprimer ou de la partager.
class EditiqueDocument extends Equatable {
  final EditiqueDocumentType type;

  /// Les octets du PDF, tels que reçus.
  final Uint8List bytes;

  /// Numéro de pièce (`ETL-AI-2526-000087`), extrait du `Content-Disposition`
  /// quand le serveur l'a posé.
  ///
  /// `null` quand l'en-tête est absent ou illisible : il n'est **pas** décrit
  /// dans le contrat OpenAPI, donc jamais garanti. Pour [EditiqueDocumentType]
  /// archivées, le numéro est de toute façon déjà connu localement (table
  /// `generated_documents`, scellée à l'ACK de synchro) ; pour un relevé ou un
  /// quitus, cet en-tête est la **seule** source du numéro — le serveur ne le
  /// persiste nulle part.
  final String? documentNumber;

  /// Nom de fichier suggéré, toujours renseigné (repli construit à partir du
  /// type quand le serveur n'en propose pas).
  final String fileName;

  const EditiqueDocument({
    required this.type,
    required this.bytes,
    required this.fileName,
    this.documentNumber,
  });

  /// Relais de [EditiqueDocumentType.isReplayable] — voir sa documentation
  /// avant d'offrir un « Réessayer » sur un échec d'émission.
  bool get isReplayable => type.isReplayable;

  @override
  List<Object?> get props => [type, bytes, documentNumber, fileName];
}
