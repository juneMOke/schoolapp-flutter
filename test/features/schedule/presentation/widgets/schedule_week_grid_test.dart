import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

TimetableCell _cell(String classId, String subject) => TimetableCell(
  sessionId: 'sess-$classId-$subject',
  coursId: 'cours-$classId-$subject',
  classroomId: classId,
  classroomLabel: 'Classe $classId',
  teacherId: 't-1',
  teacherLabel: 'Enseignant',
  subjectLabel: subject,
  room: 'Salle 12',
);

WeeklyTimetable _timetable() => WeeklyTimetable(
  academicYearId: 'ay-1',
  days: const [Weekday.mon, Weekday.tue, Weekday.wed],
  rows: [
    TimetableRow(
      timeSlot: const TimeSlot(
        id: 's0',
        order: 0,
        startTime: '08:00:00',
        endTime: '08:50:00',
      ),
      cells: {
        Weekday.mon: _cell('A', 'Mathématiques'),
        Weekday.tue: _cell('B', 'Français'),
      },
    ),
    const TimetableRow(
      timeSlot: TimeSlot(
        id: 's1',
        order: 1,
        startTime: '09:40:00',
        endTime: '10:00:00',
        label: 'Récréation',
      ),
      cells: {},
    ),
    TimetableRow(
      timeSlot: const TimeSlot(
        id: 's2',
        order: 2,
        startTime: '10:00:00',
        endTime: '10:50:00',
      ),
      cells: {Weekday.wed: _cell('A', 'Histoire')},
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
      body: SingleChildScrollView(
        // 760 = seuil « large » (toutes les colonnes) et tient dans le viewport
        // de test par défaut (800) sans débordement horizontal.
        child: SizedBox(width: 760, child: child),
      ),
    ),
  );

  testWidgets('rend les séances et la bande récréation', (tester) async {
    final timetable = _timetable();
    await tester.pumpWidget(
      host(
        ScheduleWeekGrid(
          timetable: timetable,
          palette: ScheduleClassPalette.fromTimetable(timetable),
          today: Weekday.wed,
        ),
      ),
    );

    expect(find.text('Mathématiques'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('Histoire'), findsOneWidget);
    expect(find.textContaining('Récréation'), findsOneWidget);
    // Grille compacte : la salle est masquée.
    expect(find.textContaining('Salle 12'), findsNothing);
  });

  testWidgets('un tap sur une séance ouvre le cours de cette cellule', (
    tester,
  ) async {
    final timetable = _timetable();
    TimetableCell? opened;
    await tester.pumpWidget(
      host(
        ScheduleWeekGrid(
          timetable: timetable,
          palette: ScheduleClassPalette.fromTimetable(timetable),
          today: Weekday.wed,
          onOpenCell: (cell) => opened = cell,
        ),
      ),
    );

    await tester.tap(find.text('Mathématiques'));
    await tester.pump();

    expect(opened, isNotNull);
    expect(opened!.subjectLabel, 'Mathématiques');
    expect(opened!.classroomId, 'A');
  });
}
