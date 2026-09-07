import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_pdf_kit.dart';

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
        pageFormat: EnrollmentPdfKit.pageFormat,
        header: (context) => context.pageNumber == 1
            ? EnrollmentPdfKit.header(
                overtitle: labels.overtitle,
                title: labels.title,
                subtitle: labels.subtitle(schoolYear, generatedOn),
              )
            : pw.SizedBox(),
        footer: (context) => EnrollmentPdfKit.footer(
          labels.footer(levels.length, schoolYear, generatedOn),
        ),
        build: (context) => [_table(levels, labels)],
      ),
    );

    return document.save();
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
          decoration: EnrollmentPdfKit.headerRowDecoration,
          children: [
            EnrollmentPdfKit.headerCell(labels.columnLevel),
            EnrollmentPdfKit.headerCell(labels.columnCycle),
            EnrollmentPdfKit.headerCell(labels.columnCount, alignRight: true),
          ],
        ),
        for (var i = 0; i < levels.length; i++)
          pw.TableRow(
            decoration: EnrollmentPdfKit.rowDecoration(i),
            children: [
              EnrollmentPdfKit.cell(levels[i].displayLabel),
              EnrollmentPdfKit.cell(levels[i].cycle),
              EnrollmentPdfKit.cell('${levels[i].value}', alignRight: true),
            ],
          ),
      ],
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
