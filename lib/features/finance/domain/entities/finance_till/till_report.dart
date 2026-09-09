import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Le **rapport d'encaissements** d'une caisse sur une fenêtre, tel que le
/// serveur vient de le rendre.
///
/// Purement en mémoire : rien n'est écrit sur le disque ni dans la base
/// chiffrée. C'est la présentation qui décide de l'imprimer ou de le partager.
///
/// ⚠️ **Ce n'est pas une pièce d'éditique**, et [EditiqueDocument] n'est
/// délibérément pas réutilisé pour le porter. Cette pièce-ci n'est **pas
/// archivée** — le serveur n'en garde pas les octets, redemander le même
/// rapport en produit un nouveau sous un nouveau numéro. Lui donner le type et
/// l'entité de l'éditique la ferait entrer dans un cache, un delta de synchro
/// et une restitution par identifiant qui, pour elle, n'existent pas.
///
/// ⚠️ **Ce n'est pas non plus un justificatif de versement.** Un reçu atteste
/// un paiement et sert à le prouver ; ce rapport agrège une fenêtre, et le QR
/// qu'il porte atteste l'existence du document, **pas ses montants**. Il ne
/// doit jamais être présenté comme une preuve de paiement.
class TillReport extends Equatable {
  /// Les octets du PDF, tels que reçus.
  final Uint8List bytes;

  /// Le nom annoncé par le serveur — `encaissements-USD-2026-09-01_2026-09-30`.
  ///
  /// Repris **tel quel**, jamais réécrit : il porte les bornes réellement
  /// retenues, y compris quand elles ont été dérivées d'une période courante,
  /// et c'est ce qui empêche deux rapports de deux journées de s'écraser dans
  /// le dossier de téléchargement.
  final String fileName;

  const TillReport({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
