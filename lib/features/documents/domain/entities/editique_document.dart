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

  /// Jour d'émission `AAAA-MM-JJ`, lu dans l'en-tête `X-Document-Emitted-At`
  /// (une date à minuit UTC, cf. `ReceiptEmissionDay`). `null` quand le
  /// serveur ne le pose pas — pièce non archivée ou serveur antérieur.
  final String? emittedOn;

  /// URL de vérification de la pièce, lue dans `X-Document-Verification-Url`
  /// — celle que le ticket imprime en QR. `null` quand le serveur ne la pose
  /// pas.
  final String? verificationUrl;

  /// Édition de la pièce sous son numéro, lue dans `X-Document-Edition`.
  ///
  /// `null` quand le serveur ne l'annonce pas : pièce non archivée, ou pièce
  /// scellée avant que l'en-tête n'existe. Un affichage retombe alors sur
  /// l'édition 1 ([displayEdition]) ; le cache, lui, garde `null` pour ne pas
  /// écraser une édition qu'un delta lui aurait apprise.
  final int? edition;

  /// Vrai quand une réémission a rendu une remplaçante qu'elle n'a **pas**
  /// composée à cet appel (`X-Document-Replayed: true`) : la pièce était déjà
  /// remplacée, par un autre poste ou par ce même poste dont la réponse s'est
  /// perdue.
  ///
  /// L'en-tête n'est posé que sur un rejeu, jamais à `false` : `false` dit donc
  /// « pas de signal », ce qui vaut aussi pour un serveur antérieur à
  /// l'en-tête. Sans rapport avec [isReplayable], qui dit si une émission peut
  /// se rejouer sans risque.
  final bool wasReplayed;

  const EditiqueDocument({
    required this.type,
    required this.bytes,
    required this.fileName,
    this.documentNumber,
    this.documentId,
    this.emittedOn,
    this.verificationUrl,
    this.edition,
    this.wasReplayed = false,
  });

  /// L'édition à montrer : celle annoncée, sinon la première.
  int get displayEdition => edition ?? 1;

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
    emittedOn,
    verificationUrl,
    edition,
    wasReplayed,
  ];
}
