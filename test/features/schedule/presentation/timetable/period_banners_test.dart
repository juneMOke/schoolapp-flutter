import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/class_calendar_reader.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/dated_week_bar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

void main() {
  final calendar = SchoolCalendar(
    id: 'c',
    yearLabel: '2025-2026',
    status: CalendarStatus.published,
    startDate: DateTime.utc(2025, 9, 1),
    endDate: DateTime.utc(2026, 7, 3),
    framework: FrameworkState.integrated,
    revision: 1,
  );

  testWidgets('A23 : un férié dans la semaine porte son bandeau', (
    tester,
  ) async {
    final days = DaysBetween.compute(
      from: DateTime.utc(2026, 6, 29),
      to: DateTime.utc(2026, 7, 5),
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
    );
    await tester.pumpWidget(
      _host(
        PeriodBanners(
          week: ClassCalendarWeek(days: days, calendar: calendar),
        ),
      ),
    );
    expect(find.textContaining('Jour férié · Indépendance'), findsOneWidget);
    expect(find.textContaining('1 jour cette semaine'), findsOneWidget);
    expect(days[1].isClosed, isTrue);
  });

  testWidgets('R20 : hors année, la rentrée est annoncée', (tester) async {
    await tester.pumpWidget(
      _host(
        PeriodBanners(
          week: ClassCalendarWeek(
            days: const [],
            nextStart: DateTime.utc(2026, 9, 7),
          ),
        ),
      ),
    );
    expect(find.text('Hors année scolaire'), findsOneWidget);
    expect(find.textContaining('rentrée le'), findsOneWidget);
  });
}
