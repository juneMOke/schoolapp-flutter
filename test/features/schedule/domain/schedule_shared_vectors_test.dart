import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_copy.dart';

/// Vecteurs partagés du lot V0 — **les mêmes fichiers que le serveur**
/// (`src/test/resources/schedule/*.json`), copiés tels quels, à l'octet près.
/// Ne jamais les retoucher à la main : les recopier du dépôt back.
List<Map<String, dynamic>> _cases(String path) =>
    ((jsonDecode(File(path).readAsStringSync()) as Map)['cases'] as List)
        .cast<Map<String, dynamic>>();

MinuteRange _range(Map m) =>
    MinuteRange(m['startMinute'] as int, m['endMinute'] as int);

void main() {
  group('overlap-vectors', () {
    for (final c in _cases('test/fixtures/schedule/overlap-vectors.json')) {
      test(c['name'], () {
        final input = c['input'] as Map;
        expect(
          SlotOverlap.overlaps(_range(input['a']), _range(input['b'])),
          c['expected'],
        );
      });
    }
  });

  group('copy-vectors', () {
    for (final c in _cases('test/fixtures/schedule/copy-vectors.json')) {
      test(c['name'], () {
        final input = c['input'] as Map;
        final result = TimetableCopy.compute(
          targetClassroomId: '',
          slots: [
            for (final s in input['slots'] as List)
              GridSlot(
                slotId: s['slotId'],
                order: s['order'],
                range: _range(s),
              ),
          ],
          sourceCells: [
            for (final cell in (input['source'] as Map)['cells'] as List)
              SourceCell(
                day: WeekdayX.fromWire(cell['day']),
                slotId: cell['slotId'],
                coursId: cell['coursId'],
                branchId: cell['branchId'],
              ),
          ],
          targetCourses: [
            for (final course in (input['target'] as Map)['courses'] as List)
              ProgrammeCourse(
                coursId: course['coursId'],
                branchId: course['branchId'],
                teacherId: course['teacherId'],
              ),
          ],
          otherBookings: [
            for (final other in input['otherCells'] as List)
              if (other['teacherId'] != null)
                TeacherBooking(
                  teacherId: other['teacherId'],
                  day: WeekdayX.fromWire(other['day']),
                  range: _range(other),
                  classroomId: other['classroomId'],
                  classroomLabel: other['classroomId'],
                ),
          ],
        );
        final expected = c['expected'] as Map;
        expect([
          for (final cell in result.cells)
            {
              'day': cell.day.wire,
              'slotId': cell.slotId,
              'coursId': cell.coursId,
              'teacherId': cell.teacherId,
            },
        ], expected['cells']);
        expect(result.taken, expected['taken']);
        expect(result.conflicts, expected['conflicts']);
        expect(result.noEquivalent, expected['noEquivalent']);
      });
    }
  });
}
