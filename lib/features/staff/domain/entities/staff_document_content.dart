import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Les octets d'une pièce, prêts à montrer.
class StaffDocumentContent extends Equatable {
  final Uint8List bytes;

  /// `image/jpeg`, `image/png` ou `application/pdf`.
  final String mimeType;
  final String fileName;

  const StaffDocumentContent({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  bool get isPdf => mimeType == 'application/pdf';

  @override
  List<Object?> get props => [bytes, mimeType, fileName];
}
