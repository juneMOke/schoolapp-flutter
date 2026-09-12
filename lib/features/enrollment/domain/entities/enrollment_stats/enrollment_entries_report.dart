import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Le **registre des inscrits** d'une fenêtre, tel que le serveur vient de le
/// rendre en PDF.
///
/// Purement en mémoire : rien n'est écrit sur le disque ni dans la base
/// chiffrée. C'est la présentation qui le remet au spouleur.
///
/// ⚠️ **Ce n'est pas une pièce d'éditique**, et `EditiqueDocument` n'est
/// délibérément pas réutilisé pour le porter. La pièce est numérotée et
/// horodatée mais **jamais archivée** : le serveur n'en garde pas les octets,
/// et la redemander en produit une nouvelle sous un nouveau numéro. Même
/// famille que le rapport de caisse et la liste de relance.
///
/// ⚠️ **Ce n'est pas une attestation d'inscription.** L'attestation désigne un
/// élève et se remet à sa famille ; ce registre porte une fenêtre et se remet
/// à la direction. Son QR atteste l'existence du document, **pas la liste**.
class EnrollmentEntriesReport extends Equatable {
  /// Les octets du PDF, tels que reçus.
  final Uint8List bytes;

  /// Le nom annoncé par le serveur — `inscriptions-2026-09-01_2026-09-07.pdf`,
  /// ou `inscriptions-2025-2026.pdf` sur l'année, qui ne se borne pas par
  /// dates.
  ///
  /// Repris **tel quel**, jamais réécrit : il porte le périmètre réellement
  /// retenu, et c'est ce qui empêche deux registres de deux semaines de
  /// s'écraser dans le dossier de téléchargement.
  final String fileName;

  const EnrollmentEntriesReport({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
