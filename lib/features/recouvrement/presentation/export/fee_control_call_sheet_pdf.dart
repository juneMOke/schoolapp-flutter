import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_pdf_kit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **La feuille d'appel à signer** — la seule sortie matérielle de l'écran, et
/// une bonne part de sa raison d'être.
///
/// Une feuille que le percepteur emporte en classe, où chaque parent signe en
/// face du reste dû. Document autonome : il porte son en-tête, sa date et le
/// cours appliqué, parce qu'une fois posé sur un bureau il ne dit plus rien de
/// l'écran d'où il sort.
///
/// ## Ce que ce document n'est pas
///
/// Ce n'est **pas une pièce scellée** du module `documents` : aucun numéro,
/// aucune idempotence, aucune remontée. C'est une feuille de travail, produite
/// en local, imprimable sans réseau — ce qui est précisément le cas d'usage,
/// une salle de classe.
///
/// Il est reconstruit en `pw.Document`, jamais capturé de l'écran : une capture
/// perdrait le texte, donc la recherche, la sélection et l'accessibilité.
abstract final class FeeControlCallSheetPdf {
  /// Colonne de signature — c'est elle qui justifie le papier.
  static const double signatureWidth = 190;
  static const double numberWidth = 34;
  static const double amountWidth = 78;

  /// Hauteur d'une case de signature vide : de quoi écrire à la main.
  static const double signatureHeight = 26;

  static Future<Uint8List> build({
    required List<FeeControlRow> rows,
    required String context,
    required String academicYearLabel,
    required DateTime issuedOn,
    required ExchangeRate? rate,
    required AppLocalizations l10n,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: EnrollmentPdfKit.pageFormat,
        header: (_) => _header(
          context: context,
          academicYearLabel: academicYearLabel,
          issuedOn: issuedOn,
          rate: rate,
          l10n: l10n,
        ),
        build: (_) => [
          _table(rows, l10n),
          pw.SizedBox(height: 26),
          _visas(l10n),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _header({
    required String context,
    required String academicYearLabel,
    required DateTime issuedOn,
    required ExchangeRate? rate,
    required AppLocalizations l10n,
  }) {
    final mentions = <String>[
      academicYearLabel,
      l10n.feeControlCallSheetIssuedOn(_date(issuedOn)),
      // ⚠️ Le cours n'est imprimé qu'à titre de **mention légale** : aucun
      // montant de la feuille n'est converti. Absent, on n'écrit rien plutôt
      // qu'un « — » qui ferait chercher une panne.
      if (rate != null) l10n.feeControlCallSheetRate(_rate(rate)),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l10n.feeControlCallSheetTitle,
                    style: pw.TextStyle(
                      font: pw.Font.timesBold(),
                      fontSize: 16,
                      color: EnrollmentPdfKit.accent,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    context,
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: EnrollmentPdfKit.bodySize,
                      color: EnrollmentPdfKit.muted,
                    ),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (final mention in mentions)
                  pw.Text(
                    mention,
                    style: pw.TextStyle(
                      font: pw.Font.helvetica(),
                      fontSize: 8,
                      color: EnrollmentPdfKit.muted,
                    ),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: EnrollmentPdfKit.accent),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _table(List<FeeControlRow> rows, AppLocalizations l10n) {
    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(numberWidth),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(amountWidth),
        3: const pw.FixedColumnWidth(amountWidth),
        4: const pw.FixedColumnWidth(amountWidth),
        5: const pw.FixedColumnWidth(signatureWidth),
      },
      children: [
        pw.TableRow(
          decoration: EnrollmentPdfKit.headerRowDecoration,
          children: [
            EnrollmentPdfKit.headerCell(l10n.feeControlCallSheetNumber),
            EnrollmentPdfKit.headerCell(l10n.feeControlColumnStudent),
            EnrollmentPdfKit.headerCell(
              l10n.facturationDetailChargeExpectedAmountColumn,
              alignRight: true,
            ),
            EnrollmentPdfKit.headerCell(
              l10n.facturationDetailChargePaidAmountColumn,
              alignRight: true,
            ),
            EnrollmentPdfKit.headerCell(
              l10n.facturationDetailChargeRemainingAmountColumn,
              alignRight: true,
            ),
            EnrollmentPdfKit.headerCell(l10n.feeControlCallSheetSignature),
          ],
        ),
        for (final (index, row) in rows.indexed)
          pw.TableRow(
            children: [
              // La numérotation suit l'ordre REÇU — donc celui de l'écran. La
              // feuille se relit dans le même ordre que la liste.
              EnrollmentPdfKit.cell('${index + 1}'),
              _student(row),
              EnrollmentPdfKit.cell(moneyCell(row.expected), alignRight: true),
              EnrollmentPdfKit.cell(moneyCell(row.paid), alignRight: true),
              _remaining(row.remaining),
              _signature(),
            ],
          ),
      ],
    );
  }

  static pw.Widget _student(FeeControlRow row) {
    final student = row.summary.student;
    final code = row.summary.enrollmentCode;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${student.lastName} ${student.firstName}',
            style: pw.TextStyle(
              font: pw.Font.helveticaBold(),
              fontSize: EnrollmentPdfKit.bodySize,
            ),
          ),
          if (code.isNotEmpty)
            pw.Text(
              code,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: 8,
                color: EnrollmentPdfKit.muted,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _remaining(MoneyBag remaining) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        moneyCell(remaining),
        textAlign: pw.TextAlign.right,
        style: pw.TextStyle(
          font: pw.Font.helveticaBold(),
          fontSize: EnrollmentPdfKit.bodySize,
          color: remaining.isAllZero
              ? PdfColors.black
              : const PdfColor.fromInt(0xFFC0392B),
        ),
      ),
    );
  }

  /// La case vide, avec son filet : c'est là que le parent signe.
  static pw.Widget _signature() => pw.Container(
    height: signatureHeight,
    margin: const pw.EdgeInsets.fromLTRB(4, 4, 4, 4),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: EnrollmentPdfKit.muted, width: 0.5),
      ),
    ),
  );

  static pw.Widget _visas(AppLocalizations l10n) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      _visa(l10n.feeControlCallSheetVisaCollector),
      _visa(l10n.feeControlCallSheetVisaDirection),
    ],
  );

  static pw.Widget _visa(String label) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          font: pw.Font.helvetica(),
          fontSize: EnrollmentPdfKit.bodySize,
          color: EnrollmentPdfKit.muted,
        ),
      ),
      pw.SizedBox(height: 24),
      pw.Container(width: 180, height: 0.5, color: EnrollmentPdfKit.muted),
    ],
  );

  /// **Jamais un total.** En sélection mixte, les deux devises se juxtaposent
  /// dans la même cellule : le signataire voit deux dettes distinctes, pas une
  /// somme qui n'existe pas.
  ///
  /// Publique parce que c'est la règle du document, et qu'elle se vérifie sans
  /// rendre une page.
  static String moneyCell(MoneyBag bag) =>
      bag.isEmpty ? '—' : bag.entries.map(MoneyFormat.format).join(' + ');

  static String _rate(ExchangeRate rate) {
    final quote = Money.parse(
      // Le cours est en micro-unités ; le rendre en centimes de la devise
      // cotée le rapproche du format des montants de la feuille.
      (rate.rateMicros / ExchangeRate.scale * 100).round(),
      rate.quote,
    );
    return '1 ${MoneyFormat.symbolOf(rate.base)} = '
        '${MoneyFormat.format(quote)}';
  }

  static String _date(DateTime moment) =>
      '${moment.day.toString().padLeft(2, '0')}/'
      '${moment.month.toString().padLeft(2, '0')}/${moment.year}';
}
