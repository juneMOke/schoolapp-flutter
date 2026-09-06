import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';

/// Le classement par niveau, en A4.
///
/// ## Une fonction pure, et c'est délibéré
///
/// Ce rendu ne touche ni au spouleur, ni au presse-papier, ni au contexte : il
/// prend des lignes et rend des octets. C'est ce qui le rend vérifiable — un
/// test peut lire le PDF produit sans imprimante ni canal de plateforme, là où
/// un rendu qui appellerait lui-même `Printing.layoutPdf` ne serait
/// observable que de visu.
///
/// ## `MultiPage`, contrairement au ticket
///
/// Le rendu du ticket 80 mm s'interdit `pw.MultiPage`, parce qu'il compose sur
/// un rouleau de hauteur infinie et que le paquet asserte contre. Ici la
/// hauteur est finie : la contrainte tombe, et `MultiPage` redevient le bon
/// outil — une école à trente niveaux déborde d'une page.
///
/// ## La police est `times`, pas Lora
///
/// La spec demande un titre serif. Lora est un asset Flutter, pas une police
/// PDF : l'embarquer coûterait ~250 Ko à chaque export pour un tableau que
/// personne ne lit typographiquement. `times` est intégrée au format,
/// couvre les accents français, et ne demande aucun chargement.
abstract final class EnrollmentLevelsPdf {
  /// Bleu ardoise du design system, en espace PDF.
  static const PdfColor _accent = PdfColor.fromInt(0xFF1B4D6B);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5C5852);
  static const PdfColor _zebra = PdfColor.fromInt(0xFFF4F1EA);

  static const double _titleSize = 24;
  static const double _overtitleSize = 8;
  static const double _bodySize = 10;

  /// Compose le document.
  ///
  /// [levels] arrive **déjà trié et filtré** par l'écran : le PDF montre
  /// exactement ce que la carte montrait, jamais un ordre ou un périmètre
  /// différent. Un export qui re-trierait serait un second écran à tenir
  /// d'accord avec le premier.
  static Future<Uint8List> render({
    required List<LevelStat> levels,
    required String schoolYear,
    required String generatedOn,
    required PdfLevelsLabels labels,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 16 * PdfPageFormat.mm,
          marginBottom: 16 * PdfPageFormat.mm,
          marginLeft: 14 * PdfPageFormat.mm,
          marginRight: 14 * PdfPageFormat.mm,
        ),
        header: (context) => context.pageNumber == 1
            ? _header(schoolYear, generatedOn, labels)
            : pw.SizedBox(),
        footer: (context) =>
            _footer(levels.length, schoolYear, generatedOn, labels),
        build: (context) => [_table(levels, labels)],
      ),
    );

    return document.save();
  }

  static pw.Widget _header(
    String schoolYear,
    String generatedOn,
    PdfLevelsLabels labels,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          labels.overtitle.toUpperCase(),
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: _overtitleSize,
            letterSpacing: 1,
            color: _accent,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          labels.title,
          style: pw.TextStyle(
            font: pw.Font.timesBold(),
            fontSize: _titleSize,
            color: _accent,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          labels.subtitle(schoolYear, generatedOn),
          style: pw.TextStyle(
            font: pw.Font.helvetica(),
            fontSize: _bodySize,
            color: _muted,
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _table(List<LevelStat> levels, PdfLevelsLabels labels) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        // L'en-tête est **souligné**, pas coloré en fond : à l'impression noir
        // et blanc d'une imprimante de bureau, un aplat se lit comme une ligne
        // de données grisée.
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _accent, width: 1.5),
            ),
          ),
          children: [
            _headerCell(labels.columnLevel),
            _headerCell(labels.columnCycle),
            _headerCell(labels.columnCount, alignRight: true),
          ],
        ),
        for (var i = 0; i < levels.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? const pw.BoxDecoration(color: _zebra) : null,
            children: [
              _cell(levels[i].displayLabel),
              _cell(levels[i].cycle),
              _cell('${levels[i].value}', alignRight: true),
            ],
          ),
      ],
    );
  }

  static pw.Widget _headerCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          font: pw.Font.helveticaBold(),
          fontSize: _bodySize,
          color: _accent,
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(font: pw.Font.helvetica(), fontSize: _bodySize),
      ),
    );
  }

  /// Nombre de lignes, année scolaire, date de génération.
  ///
  /// Le pied porte le **périmètre** du document : sans lui, une feuille
  /// imprimée puis posée sur un bureau ne dit plus de quelle année ni de quel
  /// jour elle parle, et deux exports d'années différentes deviennent
  /// indiscernables.
  static pw.Widget _footer(
    int rowCount,
    String schoolYear,
    String generatedOn,
    PdfLevelsLabels labels,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        labels.footer(rowCount, schoolYear, generatedOn),
        style: pw.TextStyle(
          font: pw.Font.helvetica(),
          fontSize: 8,
          color: _muted,
        ),
      ),
    );
  }
}

/// Les libellés du document, injectés depuis l'écran.
///
/// Le rendu ne connaît **aucune** chaîne traduisible : il ne peut pas atteindre
/// `AppLocalizations` sans un `BuildContext`, et lui en donner un le rendrait
/// intestable. L'appelant traduit, ce rendu compose.
class PdfLevelsLabels {
  final String overtitle;
  final String title;
  final String columnLevel;
  final String columnCycle;
  final String columnCount;
  final String Function(String schoolYear, String generatedOn) subtitle;
  final String Function(int rowCount, String schoolYear, String generatedOn)
  footer;

  const PdfLevelsLabels({
    required this.overtitle,
    required this.title,
    required this.columnLevel,
    required this.columnCycle,
    required this.columnCount,
    required this.subtitle,
    required this.footer,
  });
}
