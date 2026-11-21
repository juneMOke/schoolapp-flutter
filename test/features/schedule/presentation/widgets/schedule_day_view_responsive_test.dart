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
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_free_slot_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _days = [
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
  Weekday.sat,
];

const _first = TimeSlot(
  id: 's0',
  order: 0,
  startTime: '08:00:00',
  endTime: '08:50:00',
);
const _second = TimeSlot(
  id: 's1',
  order: 1,
  startTime: '09:00:00',
  endTime: '09:50:00',
);

TimetableCell _cell({String label = 'Mme Kabila', String? room}) =>
    TimetableCell(
      sessionId: 'sess-1',
      coursId: 'cours-1',
      classroomId: 'A',
      classroomLabel: label,
      teacherId: 't-1',
      teacherLabel: label,
      subjectLabel: 'Mathématiques',
      room: room,
    );

WeeklyTimetable _timetable(TimetableCell cell) => WeeklyTimetable(
  academicYearId: 'ay-1',
  days: _days,
  rows: [
    TimetableRow(timeSlot: _first, cells: {Weekday.mon: cell}),
    const TimetableRow(timeSlot: _second, cells: {}),
  ],
);

Widget _host(Widget child, {double width = 328}) => MaterialApp(
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
      child: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

ScheduleDayView _view(
  TimetableCell cell, {
  Map<Weekday, DateTime>? dates,
  void Function(Weekday, TimeSlot)? onTapSlot,
}) => ScheduleDayView(
  timetable: _timetable(cell),
  palette: ScheduleClassPalette.byCourse(const {}),
  today: null,
  selectedDay: Weekday.mon,
  onDaySelected: (_) {},
  dates: dates,
  onTapSlot: onTapSlot,
);

void main() {
  testWidgets('les six jours tiennent sur une rangée de téléphone, datés', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _view(
          _cell(),
          dates: {
            for (final d in _days) d: DateTime.utc(2026, 11, 16 + d.index),
          },
        ),
      ),
    );
    final mon = tester.getTopLeft(find.text('Lun.'));
    final sat = tester.getTopLeft(find.text('Sam.'));
    expect(sat.dy, mon.dy, reason: 'pas de retour à la ligne');
    expect(find.text('16'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans enseignant : pas de séparateur en tête de la salle', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_view(_cell(label: '', room: 'Salle 12'))));
    expect(find.text('Salle 12'), findsOneWidget);
    expect(find.text(' · Salle 12'), findsNothing);
  });

  testWidgets('brouillon : les créneaux libres se listent et se touchent', (
    tester,
  ) async {
    final taps = <String>[];
    await tester.pumpWidget(
      _host(_view(_cell(), onTapSlot: (day, slot) => taps.add(slot.id))),
    );
    expect(find.byType(ScheduleFreeSlotRow), findsOneWidget);
    await tester.tap(find.text('Créneau libre'));
    await tester.tap(find.text('Mathématiques'));
    expect(taps, ['s1', 's0']);
  });

  testWidgets('consultation : seules les séances se listent', (tester) async {
    await tester.pumpWidget(_host(_view(_cell())));
    expect(find.byType(ScheduleFreeSlotRow), findsNothing);
  });
}
