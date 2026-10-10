import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';

/// Grille de sonnerie type : 1re 07:30-08:20, 2e 08:20-09:10, 3e 09:10-10:00,
/// récréation 10:00-10:20, 4e 10:20-11:10.
const List<TimeSlot> kSchoolSlots = [
  TimeSlot(id: 's1', order: 1, startTime: '07:30:00', endTime: '08:20:00'),
  TimeSlot(id: 's2', order: 2, startTime: '08:20:00', endTime: '09:10:00'),
  TimeSlot(id: 's3', order: 3, startTime: '09:10:00', endTime: '10:00:00'),
  TimeSlot(id: 's4', order: 4, startTime: '10:20:00', endTime: '11:10:00'),
];

TimetableCell cellOf(String coursId, {String subject = 'Maths'}) =>
    TimetableCell(
      sessionId: 'session-$coursId',
      coursId: coursId,
      classroomId: 'room-$coursId',
      classroomLabel: '7e A',
      teacherId: 't1',
      teacherLabel: 'Prof',
      subjectLabel: subject,
    );

/// [sessions] : `(jour, créneau) → cours`.
WeeklyTimetable timetableOf(Map<(Weekday, String), String> sessions) {
  final days = {for (final key in sessions.keys) key.$1}.toList();
  return WeeklyTimetable(
    academicYearId: 'ay',
    teacherId: 't1',
    days: days,
    rows: [
      for (final slot in kSchoolSlots)
        TimetableRow(
          timeSlot: slot,
          cells: {
            for (final d in days)
              d: switch (sessions[(d, slot.id)]) {
                final String coursId => cellOf(coursId),
                null => null,
              },
          },
        ),
    ],
  );
}

JournalEntry entryOf({
  required String coursId,
  required DateTime date,
  required String slot,
  String? id,
  String? chapitreId,
  JournalFields fields = const JournalFields(objectif: 'O', contenu: 'C'),
  RecordSyncState syncState = RecordSyncState.synced,
}) => JournalEntry(
  id: id ?? '$coursId|${date.toIso8601String()}|$slot',
  coursId: coursId,
  date: date,
  timeSlotId: slot,
  chapitreId: chapitreId,
  fields: fields,
  syncState: syncState,
);
