import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/month_layout.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/school_calendar_month_grid.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/year/school_calendar_year_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../test_helpers/reference_formats.dart';

DateTime d(int m, int day) => DateTime.utc(2026, m, day);

CalendarElement el(
  String id,
  CalendarNature nature,
  DateTime s,
  DateTime e, {
  CalendarSource source = CalendarSource.school,
}) => CalendarElement(
  id: id,
  source: source,
  nature: nature,
  title: 'Élément $id au long intitulé qui déborde',
  startDate: s,
  endDate: e,
);

final _june = [
  el(
    'p4',
    CalendarNature.period,
    d(4, 13),
    d(7, 3),
    source: CalendarSource.national,
  ),
  el('ex', CalendarNature.exam, d(6, 15), d(6, 26)),
  el(
    'fer',
    CalendarNature.publicHoliday,
    d(6, 30),
    d(6, 30),
    source: CalendarSource.national,
  ),
  el('a', CalendarNature.assessment, d(6, 9), d(6, 10)),
  el('b', CalendarNature.schoolLife, d(6, 9), d(6, 9)),
  el('c', CalendarNature.schoolLife, d(6, 9), d(6, 9)),
  el('e', CalendarNature.schoolLife, d(6, 9), d(6, 9)),
];

void main() {
  group('MonthLayout', () {
    test('juin 2026 : 5 semaines, lundi 1er, période au premier couloir', () {
      final weeks = MonthLayout.compute(
        year: 2026,
        month: 6,
        elements: _june,
        maxLanes: 4,
      );
      expect(weeks, hasLength(5));
      expect(weeks.first.days.first, d(6, 1));
      for (final week in weeks) {
        final period = week.bands.where((b) => b.element.id == 'p4');
        if (period.isNotEmpty) expect(period.single.lane, 0);
      }
    });

    test('une bande se coupe au bord de la semaine', () {
      final weeks = MonthLayout.compute(
        year: 2026,
        month: 6,
        elements: _june,
        maxLanes: 4,
      );
      final exam = [
        for (final w in weeks) ...w.bands.where((b) => b.element.id == 'ex'),
      ];
      expect(exam, hasLength(2));
      expect(
        (exam[0].startCol, exam[0].endCol, exam[0].continuesAfter),
        (0, 6, true),
      );
      expect(
        (exam[1].startCol, exam[1].endCol, exam[1].continuesBefore),
        (0, 4, true),
      );
    });

    test('au-delà des couloirs, « +n autres » sur la colonne', () {
      final week = MonthLayout.compute(
        year: 2026,
        month: 6,
        elements: _june,
        maxLanes: 3,
      )[1];
      // Mardi 9 : période + a + b + c + e → 3 couloirs, 2 cachés.
      expect(week.hiddenByCol[1], 2);
      expect(week.hiddenByCol[2], 0);
    });
  });

  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) => Column(
            children: [
              SchoolCalendarMonthGrid(
                year: 2026,
                month: 6,
                elements: _june,
                today: d(6, 10),
                compact: c.maxWidth < AppBreakpoints.calendarMonthCompactMax,
                onDayTap: (_) {},
                onElementTap: (_) {},
              ),
              SchoolCalendarYearGrid(
                months: [
                  for (var m = 9; m <= 12; m++) DateTime.utc(2025, m),
                  for (var m = 1; m <= 7; m++) d(m, 1),
                ],
                elements: _june,
                today: d(6, 10),
                onMonthTap: (_) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );

  testAtReferenceFormats('mois et année sans débordement', (
    tester,
    format,
  ) async {
    await tester.pumpWidget(host(const SizedBox()));
    await tester.pumpWidget(host(const SizedBox()));
    expect(find.byType(SchoolCalendarMonthGrid), findsOneWidget);
    expect(find.text('10'), findsWidgets);
  });

  testWidgets('cibles du mois ≥ 48 dp au téléphone', (tester) async {
    setTestWindow(tester, const Size(360, 740));
    await tester.pumpWidget(host(const SizedBox()));
    final cell = tester.getSize(
      find.bySemanticsLabel(RegExp('10 juin 2026')).first,
    );
    expect(cell.height, greaterThanOrEqualTo(48));
  });
}
