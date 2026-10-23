import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_pdf_kit.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **La liste du personnel**, telle que « Qui sont-ils » l'affiche : mêmes
/// lignes, même ordre, même filtre. Le seul export de la V1.
///
/// Composée sur la tablette à partir du fichier local : elle s'imprime hors
/// ligne, agents pas encore synchronisés compris — leur matricule, que seul le
/// serveur attribue, s'y lit « en attente ».
///
/// Reconstruite en `pw.Document`, jamais capturée de l'écran : une capture
/// perdrait le texte. Le gabarit est celui des exports de l'école
/// ([EnrollmentPdfKit]) : deux feuilles posées côte à côte se reconnaissent.
abstract final class HrStaffListPdf {
  static const double _numberWidth = 76;
  static const double _contractWidth = 78;
  static const double _entryWidth = 60;
  static const double _seniorityWidth = 52;

  static Future<Uint8List> build({
    required List<StaffFileRow> rows,
    required HrRosterQuery query,
    required String today,
    required String? academicYear,
    required String? schoolName,
    required String issuedDate,
    required String issuedTime,
    required AppLocalizations l10n,
  }) {
    final document = pw.Document(title: l10n.hrPdfTitle);
    final scope = query.isFiltering
        ? HrPersonnelLabels.scope(l10n, query)
        : l10n.hrPdfScopeAll;
    final agents = l10n.hrAgentsCount(rows.length);
    final sort = HrPersonnelLabels.pdfSort(l10n, query.sort);

    document.addPage(
      pw.MultiPage(
        pageFormat: EnrollmentPdfKit.pageFormat,
        header: (context) => context.pageNumber == 1
            ? EnrollmentPdfKit.header(
                overtitle: l10n.hrPdfOvertitle,
                title: l10n.hrPdfTitle,
                subtitle: academicYear == null
                    ? l10n.hrPdfSubtitleNoYear(scope, agents, sort)
                    : l10n.hrPdfSubtitle(scope, agents, sort, academicYear),
              )
            : pw.SizedBox(),
        footer: (context) => EnrollmentPdfKit.footer(
          schoolName == null || schoolName.trim().isEmpty
              ? l10n.hrPdfFooterNoSchool(
                  issuedDate,
                  issuedTime,
                  context.pageNumber,
                  context.pagesCount,
                )
              : l10n.hrPdfFooter(
                  issuedDate,
                  issuedTime,
                  context.pageNumber,
                  context.pagesCount,
                  schoolName,
                ),
        ),
        build: (_) => [_table(rows, today: today, l10n: l10n)],
      ),
    );
    return document.save();
  }

  static pw.Widget _table(
    List<StaffFileRow> rows, {
    required String today,
    required AppLocalizations l10n,
  }) => pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(_numberWidth),
      1: pw.FlexColumnWidth(2),
      2: pw.FlexColumnWidth(1.4),
      3: pw.FlexColumnWidth(1),
      4: pw.FixedColumnWidth(_contractWidth),
      5: pw.FixedColumnWidth(_entryWidth),
      6: pw.FixedColumnWidth(_seniorityWidth),
    },
    children: [
      // Répété en tête de chaque page : une feuille 2 sans en-tête de colonnes
      // ne se relit plus seule.
      pw.TableRow(
        repeat: true,
        decoration: EnrollmentPdfKit.headerRowDecoration,
        children: [
          EnrollmentPdfKit.headerCell(l10n.hrPdfColNumber),
          EnrollmentPdfKit.headerCell(l10n.hrPdfColAgent),
          EnrollmentPdfKit.headerCell(l10n.hrPdfColJob),
          EnrollmentPdfKit.headerCell(l10n.hrPdfColCategory),
          EnrollmentPdfKit.headerCell(l10n.hrPdfColContract),
          EnrollmentPdfKit.headerCell(l10n.hrPdfColEntry),
          EnrollmentPdfKit.headerCell(l10n.hrPdfColSeniority, alignRight: true),
        ],
      ),
      for (final (index, row) in rows.indexed)
        pw.TableRow(
          decoration: index.isOdd
              ? const pw.BoxDecoration(color: EnrollmentPdfKit.zebra)
              : null,
          children: [
            _number(row.member.staffNumber, l10n),
            EnrollmentPdfKit.cell(row.member.fullName),
            EnrollmentPdfKit.cell(row.member.jobTitle?.trim() ?? ''),
            EnrollmentPdfKit.cell(
              HrPersonnelLabels.category(
                l10n,
                HrCategoryKey.of(row.member.category),
              ),
            ),
            EnrollmentPdfKit.cell(StaffLabels.contract(l10n, row.kind)),
            EnrollmentPdfKit.cell(
              HrPersonnelLabels.dayMonthYear(row.member.entryDate) ?? '',
            ),
            EnrollmentPdfKit.cell(
              HrPersonnelLabels.seniority(
                l10n,
                entryDate: row.member.entryDate,
                today: today,
              ),
              alignRight: true,
            ),
          ],
        ),
    ],
  );

  /// Le matricule en chasse fixe ; « en attente » tant que le serveur ne l'a
  /// pas attribué — jamais un numéro inventé par la tablette.
  static pw.Widget _number(String? number, AppLocalizations l10n) {
    final value = number?.trim() ?? '';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        value.isEmpty ? l10n.hrPdfNumberPending : value,
        style: pw.TextStyle(
          font: value.isEmpty ? pw.Font.helveticaOblique() : pw.Font.courier(),
          fontSize: EnrollmentPdfKit.bodySize - 1,
          color: value.isEmpty ? EnrollmentPdfKit.muted : PdfColors.black,
        ),
      ),
    );
  }
}
