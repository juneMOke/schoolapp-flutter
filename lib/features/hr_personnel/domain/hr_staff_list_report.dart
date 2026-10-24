import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// La **liste du personnel** (pièce LP) telle que le serveur vient de la
/// rendre : numérotée, horodatée, **non archivée** — la redemander en produit
/// une autre, sous un autre numéro. Purement en mémoire.
class HrStaffListReport extends Equatable {
  final Uint8List bytes;

  /// Le nom annoncé par le serveur, repris tel quel.
  final String fileName;

  const HrStaffListReport({required this.bytes, required this.fileName});

  @override
  List<Object?> get props => [bytes, fileName];
}
