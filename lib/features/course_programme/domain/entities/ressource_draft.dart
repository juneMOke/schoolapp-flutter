import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// Une ressource en cours de saisie dans la modale d'un chapitre, pas encore
/// jointe. Un document porte ses octets ; un lien son adresse ; un manuel sa
/// référence.
class RessourceDraft extends Equatable {
  final String id;
  final RessourceType type;
  final String nom;
  final String? url;
  final String? reference;
  final Uint8List? bytes;
  final String? mimeType;
  final String? fileName;
  final String? sha256;

  const RessourceDraft({
    required this.id,
    required this.type,
    required this.nom,
    this.url,
    this.reference,
    this.bytes,
    this.mimeType,
    this.fileName,
    this.sha256,
  });

  /// Une adresse acceptée : `http(s)://`, un point après l'hôte.
  static final RegExp urlPattern = RegExp(r'^https?://\S+\.\S+$');

  /// Plafond d'un fichier joint (décision 3 du plan : 10 Mo au sens de
  /// Spring, donc 10 × 1024²).
  static const int maxBytes = 10 * 1024 * 1024;

  bool get isValid => switch (type) {
    RessourceType.document => nom.trim().isNotEmpty && bytes != null,
    RessourceType.lien =>
      nom.trim().isNotEmpty && urlPattern.hasMatch(url?.trim() ?? ''),
    RessourceType.manuel =>
      nom.trim().isNotEmpty && (reference?.trim().isNotEmpty ?? false),
  };

  @override
  List<Object?> get props => [
    id,
    type,
    nom,
    url,
    reference,
    bytes?.length,
    mimeType,
    fileName,
    sha256,
  ];
}
