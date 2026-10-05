import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// Une ressource rattachée à un chapitre. Un `document` a ses octets dans le
/// magasin chiffré de la tablette (à envoyer, ou copie de lecture) ; un `lien`
/// porte [url] ; un `manuel` porte [reference].
class ChapitreRessource extends Equatable {
  final String id;
  final String chapitreId;
  final RessourceType type;
  final String nom;
  final String? url;
  final String? reference;

  /// Poids du fichier en octets (document seulement).
  final int? taille;
  final String? sha256;
  final String? mimeType;
  final String? fileName;
  final ProgrammeSyncState syncState;
  final String? rejectionCode;

  const ChapitreRessource({
    required this.id,
    required this.chapitreId,
    required this.type,
    required this.nom,
    this.url,
    this.reference,
    this.taille,
    this.sha256,
    this.mimeType,
    this.fileName,
    this.syncState = ProgrammeSyncState.synced,
    this.rejectionCode,
  });

  /// Ce qu'une ligne affiche sous l'intitulé : l'adresse, la référence, ou le
  /// nom du fichier.
  String? get detail => switch (type) {
    RessourceType.lien => url,
    RessourceType.manuel => reference,
    RessourceType.document => fileName,
  };

  @override
  List<Object?> get props => [
    id,
    chapitreId,
    type,
    nom,
    url,
    reference,
    taille,
    sha256,
    mimeType,
    fileName,
    syncState,
    rejectionCode,
  ];
}
