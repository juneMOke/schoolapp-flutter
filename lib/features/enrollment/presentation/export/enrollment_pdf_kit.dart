import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Le **gabarit commun** des exports PDF du module Inscriptions.
///
/// Deux documents le partagent — le classement par niveau et la liste
/// nominative du jour — et c'est le point : posés côte à côte sur un bureau,
/// ils doivent se reconnaître comme deux pages de la même école. Dupliquer le
/// chrome, c'était garantir qu'ils divergent à la première retouche.
///
/// ## La police est `times`, pas Lora
///
/// La spec demande un titre serif. Lora est un asset Flutter, pas une police
/// PDF : l'embarquer coûterait ~250 Ko à chaque export pour un tableau que
/// personne ne lit typographiquement. `times` est intégrée au format, couvre
/// les accents français, et ne demande aucun chargement.
abstract final class EnrollmentPdfKit {
  /// Bleu ardoise du design system, en espace PDF.
  static const PdfColor accent = PdfColor.fromInt(0xFF1B4D6B);
  static const PdfColor muted = PdfColor.fromInt(0xFF5C5852);
  static const PdfColor zebra = PdfColor.fromInt(0xFFF4F1EA);

  static const double titleSize = 24;
  static const double overtitleSize = 8;
  static const double bodySize = 10;

  /// A4, marges 16/14 mm — le gabarit de la spec.
  static PdfPageFormat get pageFormat => PdfPageFormat.a4.copyWith(
    marginTop: 16 * PdfPageFormat.mm,
    marginBottom: 16 * PdfPageFormat.mm,
    marginLeft: 14 * PdfPageFormat.mm,
    marginRight: 14 * PdfPageFormat.mm,
  );

  /// Sur-titre capitales, titre serif, ligne de contexte.
  static pw.Widget header({
    required String overtitle,
    required String title,
    required String subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          overtitle.toUpperCase(),
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: overtitleSize,
            letterSpacing: 1,
            color: accent,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: pw.Font.timesBold(),
            fontSize: titleSize,
            color: accent,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: bodySize,
            color: muted,
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  /// Le pied porte le **périmètre** du document : sans lui, une feuille
  /// imprimée puis posée sur un bureau ne dit plus de quelle année ni de quel
  /// jour elle parle, et deux exports deviennent indiscernables.
  static pw.Widget footer(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: pw.Font.helvetica(),
          fontSize: 8,
          color: muted,
        ),
      ),
    );
  }

  /// L'en-tête de table est **souligné**, pas coloré en fond : à l'impression
  /// noir et blanc d'une imprimante de bureau, un aplat se lit comme une ligne
  /// de données grisée.
  static const pw.BoxDecoration headerRowDecoration = pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1.5)),
  );

  static pw.Widget headerCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          font: pw.Font.helveticaBold(),
          fontSize: bodySize,
          color: accent,
        ),
      ),
    );
  }

  static pw.Widget cell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: bodySize),
      ),
    );
  }

  /// Ligne zébrée un rang sur deux.
  static pw.BoxDecoration? rowDecoration(int index) =>
      index.isOdd ? const pw.BoxDecoration(color: zebra) : null;
}
