import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_pdf_kit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';

/// Le bulletin **provisoire** en PDF, rendu sur la tablette : une page par
/// agent, le même contenu que l'écran. Sans numéro ni QR — la pièce scellée
/// (BP) vient du serveur, après validation.
///
/// Les polices intégrées au format ne portent pas le signe moins
/// typographique : il s'écrit « - » ici.
abstract final class PayrollPayslipPdf {
  static final PdfColor _gold = PdfColor.fromInt(AppColors.orDoux.toARGB32());
  static final PdfColor _alert = PdfColor.fromInt(
    AppColors.presenceMarkAbsentInk.toARGB32(),
  );
  static final PdfColor _banner = PdfColor.fromInt(
    AppColors.presenceMarkLateSoft.toARGB32(),
  );

  static Future<Uint8List> build(List<PayrollPayslipContent> payslips) {
    final document = pw.Document();
    for (final content in payslips) {
      document.addPage(
        pw.Page(
          pageFormat: EnrollmentPdfKit.pageFormat,
          build: (_) => _page(content),
        ),
      );
    }
    return document.save();
  }

  static String _pdf(String text) => text.replaceAll('−', '-');

  static pw.TextStyle _style({
    double size = EnrollmentPdfKit.bodySize,
    bool bold = false,
    PdfColor? color,
  }) => pw.TextStyle(
    font: bold ? pw.Font.helveticaBold() : pw.Font.helvetica(),
    fontSize: size,
    color: color,
  );

  static pw.Widget _page(PayrollPayslipContent content) {
    final banner = content.banner;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _pdf(content.schoolName),
                    style: _style(size: 13, bold: true),
                  ),
                  if ((content.schoolAddress ?? '').isNotEmpty)
                    pw.Text(
                      _pdf(content.schoolAddress!),
                      style: _style(color: EnrollmentPdfKit.muted),
                    ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _pdf(content.title),
                  style: pw.TextStyle(
                    font: pw.Font.timesBold(),
                    fontSize: 20,
                    color: EnrollmentPdfKit.accent,
                  ),
                ),
                pw.Text(
                  _pdf(content.monthLabel),
                  style: _style(bold: true, color: _gold),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 3, color: _gold),
        if (banner != null) ...[
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            color: _banner,
            child: pw.Text(_pdf(banner), style: _style(bold: true)),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 24,
          runSpacing: 6,
          children: [
            for (final row in content.identity)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    row.label.toUpperCase(),
                    style: _style(size: 7, color: EnrollmentPdfKit.muted),
                  ),
                  pw.Text(_pdf(row.value), style: _style(bold: true)),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 14),
        for (final row in content.gains) _row(row),
        _row(content.gross, bold: true),
        for (final row in content.deductions) _row(row, color: _alert),
        pw.Divider(),
        _row(content.net, bold: true, size: 14),
        pw.Text(
          _pdf(content.legalNote),
          style: _style(size: 8, color: EnrollmentPdfKit.muted),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          color: EnrollmentPdfKit.zebra,
          child: pw.Text(_pdf(content.attendance), style: _style(size: 8)),
        ),
        pw.SizedBox(height: 6),
        pw.Text(_pdf(content.payment), style: _style()),
        pw.Spacer(),
        pw.Row(
          children: [
            for (final signature in content.signatures)
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Divider(),
                    pw.Text(
                      _pdf(signature),
                      style: _style(size: 8, color: EnrollmentPdfKit.muted),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _row(
    PayslipRow row, {
    bool bold = false,
    double size = EnrollmentPdfKit.bodySize,
    PdfColor? color,
  }) {
    final note = row.note;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _pdf(row.label),
                  style: _style(size: size, bold: bold, color: color),
                ),
                if (note != null)
                  pw.Text(
                    _pdf(note),
                    style: _style(size: 8, color: EnrollmentPdfKit.muted),
                  ),
              ],
            ),
          ),
          pw.Text(
            _pdf(row.value),
            style: _style(size: size, bold: bold, color: color),
          ),
        ],
      ),
    );
  }
}
