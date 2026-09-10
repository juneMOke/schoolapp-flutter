import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// La **liste de relance** telle que le serveur vient de la rendre.
///
/// Purement en mémoire : rien n'est écrit sur le disque ni dans la base
/// chiffrée. C'est la présentation qui décide de l'imprimer ou de la partager.
///
/// ⚠️ **Ce n'est pas une pièce d'éditique**, et `EditiqueDocument` n'est
/// délibérément pas réutilisé pour la porter. Comme `RP` et `RI`, `LR` est
/// numérotée et scellée mais **jamais archivée** : le serveur n'en garde pas
/// les octets, redemander la même liste en produit une nouvelle sous un nouveau
/// numéro. Lui donner le type et l'entité de l'éditique la ferait entrer dans un
/// cache, un delta de synchro et une restitution par identifiant qui, pour elle,
/// n'existent pas. Le numéro sert la **vérification**, pas le rappel.
///
/// ⚠️ **Elle n'atteste rien.** Un reçu prouve un mouvement d'argent ; celle-ci
/// désigne qui appeler. Son sceau atteste que l'établissement l'a émise à cette
/// date — pas l'exactitude des montants, qui viennent de l'appareil.
class RelanceList extends Equatable {
  /// Les octets du PDF, tels que reçus.
  final Uint8List bytes;

  /// Le nom annoncé par le serveur — `relance-6eme-A-2026-09-10.pdf`.
  ///
  /// Repris **tel quel**, jamais réécrit : il porte le périmètre réellement
  /// retenu, et c'est ce qui empêche deux listes de deux groupes de s'écraser
  /// dans le dossier de téléchargement.
  final String fileName;

  const RelanceList({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
