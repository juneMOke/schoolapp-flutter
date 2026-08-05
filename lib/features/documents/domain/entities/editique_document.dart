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
  /// `null` quand l'en-tête est absent ou illisible. Pour [EditiqueDocumentType]
  /// archivées, le numéro est de toute façon déjà connu localement (table
  /// `generated_documents`, scellée à l'ACK de synchro) ; pour un relevé ou un
  /// quitus, cet en-tête est la **seule** source du numéro — le serveur ne le
  /// persiste nulle part.
  final String? documentNumber;

  /// Identifiant d'archive de la pièce, lu dans l'en-tête `X-Document-Id`.
  ///
  /// C'est ce qui permet de désigner la pièce sans dépendre de son numéro : le
  /// re-téléchargement à l'identique (`GET /editique/documents/{id}`) et
  /// l'indexation du cache hors ligne s'en servent.
  ///
  /// `null` sur un relevé ou un quitus, et ce n'est pas une lacune : le serveur
  /// ne les conserve pas, donc il n'existe aucun identifiant à annoncer. Mettre
  /// l'un d'eux en cache sous une référence inventée créerait une entrée dont la
  /// relecture échouerait pour toujours.
  final String? documentId;

  /// Nom de fichier suggéré, toujours renseigné (repli construit à partir du
  /// type quand le serveur n'en propose pas).
  final String fileName;

  const EditiqueDocument({
    required this.type,
    required this.bytes,
    required this.fileName,
    this.documentNumber,
    this.documentId,
  });

  /// Relais de [EditiqueDocumentType.isReplayable] — voir sa documentation
  /// avant d'offrir un « Réessayer » sur un échec d'émission.
  bool get isReplayable => type.isReplayable;

  @override
  List<Object?> get props => [
    type,
    bytes,
    documentNumber,
    documentId,
    fileName,
  ];
}
