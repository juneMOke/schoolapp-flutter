import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/models/timetable_row_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

void main() {
  group('TimetableRowModel.fromJson (parsing manuel de cells)', () {
    test('cases nullables préservées : null = créneau libre', () {
      final json = <String, dynamic>{
        'timeSlot': {
          'id': 'ts-1',
          'order': 1,
          'startTime': '08:00:00',
          'endTime': '08:50:00',
          'label': null,
        },
        'cells': {
          'MON': {
            'sessionId': 'sess-1',
            'coursId': 'cours-1',
            'classroomId': 'class-1',
            'classroomLabel': '6ème A',
            'teacherId': 'teacher-1',
            'teacherLabel': 'M. Dupont',
            'subjectLabel': 'Maths',
            'room': '101',
          },
          'TUE': null,
        },
      };

      final model = TimetableRowModel.fromJson(json);

      expect(model.cells['MON'], isNotNull);
      expect(model.cells['TUE'], isNull);
      expect(model.cells.containsKey('TUE'), isTrue);
    });

    test('cells absent -> map vide (défensif)', () {
      final json = <String, dynamic>{
        'timeSlot': {
          'id': 'ts-2',
          'order': 2,
          'startTime': '09:00:00',
          'endTime': '09:50:00',
        },
      };

      final model = TimetableRowModel.fromJson(json);

      expect(model.cells, isEmpty);
    });

    test('toEntity : clés String -> Weekday, valeurs nullables préservées', () {
      final json = <String, dynamic>{
        'timeSlot': {
          'id': 'ts-3',
          'order': 3,
          'startTime': '10:00:00',
          'endTime': '10:50:00',
        },
        'cells': {
          'MON': {
            'sessionId': 'sess-1',
            'coursId': 'cours-1',
            'classroomId': 'class-1',
            'classroomLabel': '6ème A',
            'teacherId': 'teacher-1',
            'teacherLabel': 'M. Dupont',
            'subjectLabel': 'Maths',
          },
          'FRI': null,
        },
      };

      final row = TimetableRowModel.fromJson(json).toEntity();

      expect(row.timeSlot.id, 'ts-3');
      expect(row.cellFor(Weekday.mon), isNotNull);
      expect(row.cellFor(Weekday.mon)!.subjectLabel, 'Maths');
      expect(row.cells[Weekday.fri], isNull);
      expect(row.cells.containsKey(Weekday.fri), isTrue);
      // Jour absent de la ligne : accès -> null (créneau libre).
      expect(row.cellFor(Weekday.sat), isNull);
    });
  });
}
