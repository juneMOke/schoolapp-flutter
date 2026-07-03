import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_day_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

TimetableCell _cell(String subject) => TimetableCell(
  sessionId: 'sess-$subject',
  coursId: 'cours-$subject',
  classroomId: 'A',
  classroomLabel: 'Classe A',
  teacherId: 't-1',
  teacherLabel: 'Enseignant',
  subjectLabel: subject,
  room: 'Salle 12',
);

WeeklyTimetable _timetable() => WeeklyTimetable(
  academicYearId: 'ay-1',
  days: const [Weekday.mon, Weekday.tue],
  rows: [
    TimetableRow(
      timeSlot: const TimeSlot(
        id: 's0',
        order: 0,
        startTime: '08:00:00',
        endTime: '08:50:00',
      ),
      cells: {Weekday.mon: _cell('Mathématiques')},
    ),
  ],
);

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 600, child: child)),
    ),
  );

  testWidgets('jour avec cours : rangée avec salle visible', (tester) async {
    final timetable = _timetable();
    await tester.pumpWidget(
      host(
        ScheduleDayView(
          timetable: timetable,
          palette: ScheduleClassPalette.fromTimetable(timetable),
          today: Weekday.mon,
          selectedDay: Weekday.mon,
          onDaySelected: (_) {},
        ),
      ),
    );

    expect(find.text('Mathématiques'), findsOneWidget);
    // Vue Jour : la salle est visible.
    expect(find.textContaining('Salle 12'), findsOneWidget);
  });

  testWidgets('jour sans cours : état vide dédié', (tester) async {
    final timetable = _timetable();
    await tester.pumpWidget(
      host(
        ScheduleDayView(
          timetable: timetable,
          palette: ScheduleClassPalette.fromTimetable(timetable),
          today: Weekday.mon,
          selectedDay: Weekday.tue,
          onDaySelected: (_) {},
        ),
      ),
    );

    expect(find.text('Aucun cours ce jour'), findsOneWidget);
  });

  testWidgets('sélection d\'un jour : notifie onDaySelected', (tester) async {
    final timetable = _timetable();
    Weekday? selected;
    await tester.pumpWidget(
      host(
        ScheduleDayView(
          timetable: timetable,
          palette: ScheduleClassPalette.fromTimetable(timetable),
          today: Weekday.mon,
          selectedDay: Weekday.mon,
          onDaySelected: (day) => selected = day,
        ),
      ),
    );

    await tester.tap(find.text('Mar.'));
    await tester.pump();

    expect(selected, Weekday.tue);
  });
}
