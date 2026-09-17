import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Un document prêt à être montré, imprimé ou partagé.
///
/// **Neutre par construction** : ni type de pièce, ni domaine, ni permission.
/// Le socle d'aperçu ignore s'il montre un reçu scellé par le serveur, un
/// registre composé par lui, ou un ticket rendu sur l'appareil — et c'est
/// précisément ce qui permet aux sorties papier de l'application de partager un
/// seul écran plutôt que d'en faire diverger dix.
///
/// Purement en mémoire : rien n'est écrit sur le disque à ce stade. Ce sont les
/// gestes du pied de la visionneuse — imprimer, partager — qui décident du sort
/// des octets.
class PrintableDocument extends Equatable {
  /// Les octets du PDF, tels qu'ils seront remis au spouleur.
  final Uint8List bytes;

  /// Nom de fichier proposé au spouleur et au partage.
  ///
  /// Quand il vient du serveur (`Content-Disposition`), il porte le périmètre
  /// réellement retenu : il ne se réécrit pas côté client.
  final String fileName;

  /// Ce qui s'affiche sous le titre : numéro de pièce, période, portée.
  ///
  /// `null` quand le document n'en porte pas — la ligne disparaît alors, elle
  /// ne s'affiche pas vide.
  final String? reference;

  const PrintableDocument({
    required this.bytes,
    required this.fileName,
    this.reference,
  });

  @override
  List<Object?> get props => [bytes, fileName, reference];
}
