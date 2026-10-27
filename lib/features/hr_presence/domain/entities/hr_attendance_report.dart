import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Un PDF de présence composé par le serveur sur la même question que
/// l'écran : l'assiduité (pièce **AP**), la liste de la fiche individuelle
/// (pièce **PR**), la fiche de présence d'un agent (pièce **FP**, ou son
/// provisoire).
class HrAttendanceReport extends Equatable {
  final Uint8List bytes;

  /// Le nom donné par `Content-Disposition`, ou un nom par défaut.
  final String fileName;

  /// L'identifiant d'archive d'une pièce scellée (`X-Document-Id`) ; `null`
  /// pour une pièce horodatée ou un provisoire. Jamais gardé comme définitif :
  /// une fiche rééditée après une correction revient sous un autre.
  final String? documentId;

  const HrAttendanceReport({
    required this.bytes,
    required this.fileName,
    this.documentId,
  });

  /// Une pièce scellée et archivée (une FP de mois clos).
  bool get isSealed => documentId != null;

  @override
  List<Object?> get props => [bytes, fileName, documentId];
}
