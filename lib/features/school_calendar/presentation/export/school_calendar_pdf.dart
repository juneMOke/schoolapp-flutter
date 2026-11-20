import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:school_app_flutter/features/academics/presentation/export/sujet_copie_fonts.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';

/// Les textes de la page, résolus par l'écran (l10n, dates locales).
class SchoolCalendarPdfLabels {
  final String schoolName;
  final String title;
  final String range;
  final String publishedOn;
  final String keyDatesTitle;
  final String nationalNote;
  final String printedOn;
  final String brand;
  final List<String> weekdayInitials;
  final String Function(DateTime month) monthName;
  final String Function(CalendarNature nature) natureName;
  final String Function(CalendarElement element) dates;

  const SchoolCalendarPdfLabels({
    required this.schoolName,
    required this.title,
    required this.range,
    required this.publishedOn,
    required this.keyDatesTitle,
    required this.nationalNote,
    required this.printedOn,
    required this.brand,
    required this.weekdayInitials,
    required this.monthName,
    required this.natureName,
    required this.dates,
  });
}

/// La page imprimée d'un calendrier publié ou archivé (CAL-R17) : A4 paysage,
/// les mois de l'année en mini-mois colorés comme la vue Année (CAL-R15), la
/// légende des natures et les dates clés (périodes, examens, congés, fériés).
///
/// Composée sur l'appareil (K14) : elle s'imprime hors ligne, à partir de la
/// version enregistrée. Déterministe : mêmes éléments, même page.
class SchoolCalendarPdf {
  const SchoolCalendarPdf._();

  static PdfColor _pdf(int argb) => PdfColor.fromInt(argb);

  static Future<Uint8List> build({
    required DateTime startDate,
    required DateTime endDate,
    required List<CalendarElement> elements,
    required SchoolCalendarPdfLabels labels,
  }) async {
    final fonts = await SujetCopieFonts.load();
    final theme = pw.ThemeData.withFont(base: fonts.body, bold: fonts.bodyBold);
    final months = [
      for (
        var m = DateTime.utc(startDate.year, startDate.month);
        !m.isAfter(endDate);
        m = DateTime.utc(m.year, m.month + 1)
      )
        m,
    ];
    final keyDates = [
      for (final e in elements)
        if (e.isNational && e.nature != CalendarNature.schoolLife) e,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));
    final document = pw.Document(theme: theme);
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginLeft: 10 * PdfPageFormat.mm,
          marginRight: 10 * PdfPageFormat.mm,
          marginTop: 8 * PdfPageFormat.mm,
          marginBottom: 8 * PdfPageFormat.mm,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(labels.schoolName, style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              labels.title,
              style: pw.TextStyle(font: fonts.title, fontSize: 16),
            ),
            pw.Text(
              '${labels.range} · ${labels.publishedOn}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 6),
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 7,
                    child: pw.Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final month in months)
                          _month(month, elements, labels),
                        _legend(labels),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(flex: 3, child: _keyDates(keyDates, labels)),
                ],
              ),
            ),
            pw.Text(
              '${labels.nationalNote} · ${labels.printedOn} · ${labels.brand}',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
        ),
      ),
    );
    return document.save();
  }

  static const double _cell = 13;

  static pw.Widget _month(
    DateTime month,
    List<CalendarElement> elements,
    SchoolCalendarPdfLabels labels,
  ) {
    final last = DateTime.utc(month.year, month.month + 1, 0);
    final days = DaysBetween.compute(from: month, to: last, elements: elements);
    final leading = month.weekday - DateTime.monday;
    final cells = <pw.Widget>[
      for (final initial in labels.weekdayInitials)
        _box(initial, null, bold: true),
      for (var i = 0; i < leading; i++)
        pw.SizedBox(width: _cell, height: _cell),
      for (final day in days)
        _box(
          '${day.date.day}',
          day.topNature == null
              ? null
              : _pdf(day.topNature!.tone.soft.toARGB32()),
        ),
    ];
    return pw.Container(
      width: _cell * 7 + 6,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            labels.monthName(month),
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Wrap(children: cells),
        ],
      ),
    );
  }

  static pw.Widget _box(String text, PdfColor? fill, {bool bold = false}) =>
      pw.Container(
        width: _cell,
        height: _cell,
        alignment: pw.Alignment.center,
        color: fill,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: bold ? pw.FontWeight.bold : null,
          ),
        ),
      );

  static pw.Widget _legend(SchoolCalendarPdfLabels labels) => pw.Container(
    width: _cell * 7 + 6,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final nature in DaysBetween.priority)
          pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                color: _pdf(nature.tone.soft.toARGB32()),
              ),
              pw.SizedBox(width: 3),
              pw.Text(
                labels.natureName(nature),
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
      ],
    ),
  );

  static pw.Widget _keyDates(
    List<CalendarElement> keyDates,
    SchoolCalendarPdfLabels labels,
  ) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        labels.keyDatesTitle,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 3),
      for (final e in keyDates.take(32))
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 6,
                height: 6,
                margin: const pw.EdgeInsets.only(top: 2, right: 3),
                color: _pdf(e.nature.tone.tone.toARGB32()),
              ),
              pw.Expanded(
                child: pw.Text(
                  '${labels.dates(e)} — ${e.title}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  /// Le nom du fichier : « calendrier-2025-2026.pdf ».
  static String fileName(String yearLabel) => 'calendrier-$yearLabel.pdf';
}
