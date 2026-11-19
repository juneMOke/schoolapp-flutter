import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/class_week_builder.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_picker.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_summary.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/reference_formats.dart';

const _classroom = TimetableClassOption(
  classroomId: 'c7a',
  name: '7e CTEB A',
  cycleCode: 'SEC',
  cycleName: 'Secondaire',
  levelCode: 'CTEB7',
  levelName: '7e CTEB',
  room: 'Salle 12',
);

ClassTimetableView _view() {
  final slots = [
    for (var i = 0; i < 6; i++)
      TimeSlot(
        id: 's$i',
        order: i + 1,
        startTime: '${(7 + i).toString().padLeft(2, '0')}:30:00',
        endTime: '${(8 + i).toString().padLeft(2, '0')}:20:00',
      ),
  ];
  const courses = [
    TimetableCourse(
      coursId: 'math',
      classroomId: 'c7a',
      branchId: 'b1',
      branchLabel: 'Mathématiques',
      domainId: 'sci',
      domainOrder: 2,
      teacherId: 't1',
      teacherLabel: 'Kashala',
    ),
    TimetableCourse(
      coursId: 'fr',
      classroomId: 'c7a',
      branchId: 'b2',
      branchLabel: 'Français',
      domainId: 'lang',
      domainOrder: 1,
      teacherId: 't2',
      teacherLabel: 'Mavinga',
    ),
    TimetableCourse(
      coursId: 'eps',
      classroomId: 'c7a',
      branchId: 'b3',
      branchLabel: 'Éducation physique',
      domainId: 'dev',
      domainOrder: 3,
    ),
  ];
  return ClassTimetableView(
    classroom: _classroom,
    grid: const TimeGrid(
      id: 'g',
      name: 'École',
      isDefault: true,
      recess: MinuteRange(560, 570),
    ),
    slots: slots,
    header: const ClassTimetableHeader(
      id: 'h',
      classroomId: 'c7a',
      academicYearId: 'y',
      revision: 1,
      publishedVersion: 1,
    ),
    published: [
      for (final day in Weekday.values)
        for (var i = 0; i < 6; i++)
          ClassTimetableCell(
            id: '${day.wire}$i',
            classroomId: 'c7a',
            classroomLabel: '7e CTEB A',
            status: TimetableCellStatus.published,
            day: day,
            slotId: 's$i',
            range: MinuteRange(450 + i * 60, 500 + i * 60),
            coursId: courses[i % 3].coursId,
            teacherId: courses[i % 3].teacherId,
            subjectLabel: courses[i % 3].branchLabel,
            teacherLabel: courses[i % 3].teacherLabel,
          ),
    ],
    draft: const [],
    programme: courses,
    othersKnown: true,
  );
}

Widget _host(Widget child) => MaterialApp(
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
      child: child,
    ),
  ),
);

void main() {
  test(
    'la semaine garde le samedi, la récréation et la teinte par domaine',
    () {
      final view = _view();
      final week = ClassWeekBuilder.build(view, view.published);
      expect(week.days, Weekday.values);
      expect(week.rows.where((r) => r.timeSlot.isBreak), hasLength(1));
      final visuals = ClassWeekBuilder.courseVisuals(view);
      expect(visuals['fr'], isNot(visuals['math']));
      final cell = week.rows.first.cellFor(Weekday.mon)!;
      expect(cell.classroomLabel, 'Kashala'); // la seconde ligne : l'enseignant
    },
  );

  testAtReferenceFormats('consultation d’une classe', (tester, format) async {
    final view = _view();
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            ClassPicker(
              options: const [_classroom],
              selectedId: 'c7a',
              onSelected: (_) {},
            ),
            ClassTimetableSummary(view: view, cells: view.published),
            ScheduleWeekGrid(
              timetable: ClassWeekBuilder.build(view, view.published),
              palette: ScheduleClassPalette.byCourse(
                ClassWeekBuilder.courseVisuals(view),
              ),
              today: Weekday.wed,
              keepSaturday: true,
            ),
            ClassTimetableDistribution(view: view, cells: view.published),
          ],
        ),
      ),
    );
    expect(find.text('Mathématiques'), findsWidgets);
  });
}
