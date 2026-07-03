import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';

TimetableCell _cell(String classId) => TimetableCell(
  sessionId: 'sess-$classId',
  coursId: 'cours-$classId',
  classroomId: classId,
  classroomLabel: 'Classe $classId',
  teacherId: 't-1',
  teacherLabel: 'Enseignant',
  subjectLabel: 'Matière',
);

TimeSlot _slot(int order) => TimeSlot(
  id: 's-$order',
  order: order,
  startTime: '08:00:00',
  endTime: '08:50:00',
);

void main() {
  // A apparaît en premier (lun), B ensuite (mar), puis A réapparaît (mer).
  final timetable = WeeklyTimetable(
    academicYearId: 'ay-1',
    days: const [Weekday.mon, Weekday.tue, Weekday.wed],
    rows: [
      TimetableRow(
        timeSlot: _slot(0),
        cells: {Weekday.mon: _cell('A'), Weekday.tue: _cell('B')},
      ),
      TimetableRow(timeSlot: _slot(1), cells: {Weekday.wed: _cell('A')}),
    ],
  );

  final palette = ScheduleClassPalette.fromTimetable(timetable);

  test('assigne la couleur par ordre d\'apparition', () {
    expect(
      palette.visualForClassroom('A').accent,
      AcademicsClassVisual.forIndex(0).accent,
    );
    expect(
      palette.visualForClassroom('B').accent,
      AcademicsClassVisual.forIndex(1).accent,
    );
  });

  test(
    'même classe → même couleur (déterminisme entre grille/jour/légende)',
    () {
      expect(
        palette.visualForClassroom('A').accent,
        palette.visualForClassroom('A').accent,
      );
      // A n'a PAS pris le rang de sa réapparition : il garde le rang 0.
      expect(
        palette.visualForClassroom('A').accent,
        isNot(AcademicsClassVisual.forIndex(1).accent),
      );
    },
  );

  test('légende dédupliquée et ordonnée par apparition', () {
    final entries = palette.legendEntries;
    expect(entries.map((e) => e.classroomId).toList(), ['A', 'B']);
    expect(entries.first.classroomLabel, 'Classe A');
  });

  test('classe inconnue → repli sans lever', () {
    expect(
      palette.visualForClassroom('ZZZ').accent,
      AcademicsClassVisual.forIndex(0).accent,
    );
  });
}
