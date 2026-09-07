import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_pdf_kit.dart';

/// La liste nominative du jour, en A4.
///
/// Même gabarit que le classement par niveau ([EnrollmentPdfKit]) : les deux
/// feuilles se posent côte à côte sur un bureau et doivent se reconnaître.
///
/// ## Fonction pure, comme ses deux voisins
///
/// Elle prend des lignes et rend des octets — ni spouleur, ni presse-papier,
/// ni `BuildContext`. C'est ce qui la rend vérifiable sans imprimante.
///
/// ## Ce document est NOMINATIF
///
/// Il porte des noms d'élèves, et il quitte l'application. Il ne s'ouvre donc
/// que depuis la carte du jour, qui porte déjà sa propre permission serveur :
/// lire le pilotage ne donne pas le droit de lire les noms.
///
/// ## La colonne « Statut » de la spec n'y est pas
///
/// ⚠️ Le contrat ne la porte pas : `DayEnrollmentEntry` n'a aucun champ de
/// statut, et l'entité dit elle-même que la vérité du type tient dans
/// `formerStudent`. Le tableau à l'écran (spec l.525) ne l'affiche pas non
/// plus. Inventer une colonne — ou la remplir avec le type — donnerait à un
/// document imprimé l'autorité d'une donnée qui n'existe pas. Elle est donc
/// omise, et la question remonte au contrat.
abstract final class EnrollmentDayEntriesPdf {
  /// Compose le document.
  ///
  /// [entries] arrive dans l'ordre du serveur — chronologique — et n'est ni
  /// retrié ni refiltré ici : la feuille dit exactement ce que la carte
  /// disait.
  static Future<Uint8List> render({
    required List<DayEnrollmentEntry> entries,
    required String schoolYear,
    required String day,
    required String generatedOn,
    required PdfDayEntriesLabels labels,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: EnrollmentPdfKit.pageFormat,
        header: (context) => context.pageNumber == 1
            ? EnrollmentPdfKit.header(
                overtitle: labels.overtitle,
                title: labels.title,
                subtitle: labels.subtitle(schoolYear, day),
              )
            : pw.SizedBox(),
        footer: (context) => EnrollmentPdfKit.footer(
          labels.footer(entries.length, schoolYear, generatedOn),
        ),
        build: (context) => [_table(entries, labels)],
      ),
    );

    return document.save();
  }

  static pw.Widget _table(
    List<DayEnrollmentEntry> entries,
    PdfDayEntriesLabels labels,
  ) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(2.6),
        2: pw.FlexColumnWidth(0.9),
        3: pw.FlexColumnWidth(1.4),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: EnrollmentPdfKit.headerRowDecoration,
          children: [
            EnrollmentPdfKit.headerCell(labels.columnHour),
            EnrollmentPdfKit.headerCell(labels.columnStudent),
            EnrollmentPdfKit.headerCell(labels.columnGender),
            EnrollmentPdfKit.headerCell(labels.columnLevel),
            EnrollmentPdfKit.headerCell(labels.columnType),
            EnrollmentPdfKit.headerCell(labels.columnRecordedBy),
          ],
        ),
        for (var i = 0; i < entries.length; i++)
          pw.TableRow(
            decoration: EnrollmentPdfKit.rowDecoration(i),
            children: [
              // Même règle qu'à l'écran : une heure qui ne tombe pas le jour
              // déclaré ne dit rien de la journée exportée. Sur un document
              // imprimé, une heure fausse ne se rattrape plus.
              EnrollmentPdfKit.cell(
                entries[i].hourIsMeaningful
                    ? _hour(entries[i].createdAt)
                    : labels.noHour,
              ),
              EnrollmentPdfKit.cell(entries[i].displayName),
              EnrollmentPdfKit.cell(
                entries[i].gender == Gender.female
                    ? labels.female
                    : labels.male,
              ),
              EnrollmentPdfKit.cell(entries[i].schoolLevel),
              EnrollmentPdfKit.cell(
                entries[i].formerStudent
                    ? labels.typeReturning
                    : labels.typeFirst,
              ),
              // Un tiret, jamais une attribution inventée.
              EnrollmentPdfKit.cell(
                entries[i].recordedBy ?? labels.unknownAgent,
              ),
            ],
          ),
      ],
    );
  }

  /// `09:30` — deux chiffres, indépendant de la locale.
  static String _hour(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';
}

/// Les libellés du document, traduits par l'appelant.
///
/// Le rendu ne connaît **aucune** chaîne traduisible : il ne peut pas atteindre
/// `AppLocalizations` sans un `BuildContext`, et lui en donner un le rendrait
/// intestable.
class PdfDayEntriesLabels {
  final String overtitle;
  final String title;
  final String columnHour;
  final String columnStudent;
  final String columnGender;
  final String columnLevel;
  final String columnType;
  final String columnRecordedBy;
  final String female;
  final String male;
  final String typeFirst;
  final String typeReturning;
  final String unknownAgent;
  final String noHour;
  final String Function(String schoolYear, String day) subtitle;
  final String Function(int rowCount, String schoolYear, String generatedOn)
  footer;

  const PdfDayEntriesLabels({
    required this.overtitle,
    required this.title,
    required this.columnHour,
    required this.columnStudent,
    required this.columnGender,
    required this.columnLevel,
    required this.columnType,
    required this.columnRecordedBy,
    required this.female,
    required this.male,
    required this.typeFirst,
    required this.typeReturning,
    required this.unknownAgent,
    required this.noHour,
    required this.subtitle,
    required this.footer,
  });
}
