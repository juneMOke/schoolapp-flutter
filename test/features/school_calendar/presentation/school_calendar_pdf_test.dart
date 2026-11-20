import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/export/school_calendar_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la page A4 paysage se compose, onze mois et dates clés', () async {
    final bytes = await SchoolCalendarPdf.build(
      startDate: DateTime.utc(2025, 9, 1),
      endDate: DateTime.utc(2026, 7, 3),
      elements: [
        CalendarElement(
          id: 'f',
          source: CalendarSource.national,
          nature: CalendarNature.publicHoliday,
          title: 'Indépendance',
          startDate: DateTime.utc(2026, 6, 30),
          endDate: DateTime.utc(2026, 6, 30),
        ),
      ],
      labels: SchoolCalendarPdfLabels(
        schoolName: 'École La Fontaine',
        title: 'Calendrier scolaire — Année scolaire 2025-2026',
        range: '1 sept. → 3 juil.',
        publishedOn: 'Version publiée le 25 août 2025',
        keyDatesTitle: 'Dates clés',
        nationalNote: 'Note',
        printedOn: 'Imprimé le 10 juin 2026',
        brand: 'ETEELO CONNECT',
        weekdayInitials: const ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
        monthName: (m) => '${m.month}/${m.year}',
        natureName: (n) => n.wire,
        dates: (e) => '30 juin',
      ),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(SchoolCalendarPdf.fileName('2025-2026'), 'calendrier-2025-2026.pdf');
  });
}
