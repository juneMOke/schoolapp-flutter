import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/core/attachments/attachment_ref.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';

/// Une pièce téléchargée : sa description et ses octets.
typedef AttachmentPart = ({AttachmentRef ref, Uint8List bytes});

/// Met des pièces sous la forme que la visionneuse partagée sait montrer : un
/// PDF.
///
/// Un PDF seul passe tel quel. Des photos de pages deviennent un PDF d'une
/// page par photo, **dans l'ordre reçu**, chacune ajustée à la page sans être
/// rognée. Un PDF ne se fusionne pas avec d'autres pièces (le paquet `pdf`
/// n'en relit pas) : l'appelant ouvre alors chaque PDF à part.
abstract final class AttachmentDocument {
  /// Le document de [parts], ou `null` si elles ne se composent pas en un seul
  /// (plusieurs pièces dont un PDF, une pièce d'un autre type, ou une image
  /// que le paquet `pdf` ne sait pas décoder).
  static Future<PrintableDocument?> compose(
    List<AttachmentPart> parts, {
    required String fileName,
    String? reference,
  }) async {
    if (parts.isEmpty) return null;
    if (parts.length == 1 && parts.single.ref.isPdf) {
      return PrintableDocument(
        bytes: parts.single.bytes,
        fileName: fileName,
        reference: reference,
      );
    }
    if (!parts.every((part) => part.ref.isImage)) return null;
    final document = pw.Document();
    for (final part in parts) {
      final pw.MemoryImage image;
      try {
        image = pw.MemoryImage(part.bytes);
      } catch (_) {
        return null;
      }
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(PdfPageFormat.cm),
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
    return PrintableDocument(
      bytes: await document.save(),
      fileName: fileName,
      reference: reference,
    );
  }
}
