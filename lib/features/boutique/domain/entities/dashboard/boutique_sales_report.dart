import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Le **rapport des ventes** (pièce VB) tel que le serveur vient de le rendre.
///
/// Purement en mémoire. Comme le rapport d'encaissements, la pièce n'est **pas
/// archivée** : la redemander en produit une autre, sous un autre numéro. Ce
/// n'est pas non plus un justificatif de vente — le reçu scellé l'est.
class BoutiqueSalesReport extends Equatable {
  final Uint8List bytes;

  /// Le nom annoncé par le serveur, repris tel quel : il porte les bornes
  /// réellement retenues.
  final String fileName;

  const BoutiqueSalesReport({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
