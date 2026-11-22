import 'dart:typed_data';

import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';

/// **Un 200 ne suffit pas à faire un document.** Un portail captif ou un proxy
/// répondent 200 avec du HTML : présentés comme un PDF ou un classeur, ces
/// octets donneraient une visionneuse vide sans un mot. La garde lève une
/// [FormatException], que l'appelant traduit en panne serveur.
abstract final class ExportBytesGuard {
  /// `%PDF`.
  static const _pdfMagic = <int>[0x25, 0x50, 0x44, 0x46];

  /// `PK\x03\x04` : un `.xlsx` est une archive zip.
  static const _zipMagic = <int>[0x50, 0x4B, 0x03, 0x04];

  static const _xlsxContentType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  static void check(
    Uint8List bytes,
    String? contentType,
    RecoveryExportFormat format,
  ) {
    if (bytes.isEmpty) {
      throw const FormatException('Le document reçu est vide.');
    }
    final pdf = format == RecoveryExportFormat.pdf;
    final type = contentType?.toLowerCase() ?? '';
    final expected = pdf ? AppConstants.pdfContentType : _xlsxContentType;
    if (!type.contains(expected)) {
      throw const FormatException(
        "La réponse du serveur n'est pas le document attendu.",
      );
    }
    final magic = pdf ? _pdfMagic : _zipMagic;
    if (bytes.length < magic.length ||
        !magic.asMap().entries.every((e) => bytes[e.key] == e.value)) {
      throw const FormatException(
        'Le document reçu est illisible ou incomplet.',
      );
    }
  }
}
