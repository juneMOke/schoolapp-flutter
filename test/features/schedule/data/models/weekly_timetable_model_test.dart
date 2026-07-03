import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/models/weekly_timetable_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

void main() {
  Map<String, dynamic> cellJson(String suffix) => {
    'sessionId': 'sess-$suffix',
    'coursId': 'cours-$suffix',
    'classroomId': 'class-$suffix',
    'classroomLabel': '6ème A',
    'teacherId': 'teacher-$suffix',
    'teacherLabel': 'M. Dupont',
    'subjectLabel': 'Maths',
    'room': null,
  };

  group('WeeklyTimetableModel.fromJson + toEntity', () {
    test('reconstruit la matrice : days LUN..SAM + rows avec cases null', () {
      final json = <String, dynamic>{
        'academicYearId': 'ay-1',
        'teacherId': 'teacher-1',
        'classroomId': null,
        'days': ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
        'rows': [
          {
            'timeSlot': {
              'id': 'ts-1',
              'order': 1,
              'startTime': '08:00:00',
              'endTime': '08:50:00',
            },
            'cells': {'MON': cellJson('1'), 'TUE': null},
          },
        ],
      };

      final tt = WeeklyTimetableModel.fromJson(json).toEntity();

      expect(tt.academicYearId, 'ay-1');
      expect(tt.teacherId, 'teacher-1');
      expect(tt.classroomId, isNull);
      expect(tt.days, const [
        Weekday.mon,
        Weekday.tue,
        Weekday.wed,
        Weekday.thu,
        Weekday.fri,
        Weekday.sat,
      ]);
      expect(tt.rows, hasLength(1));

      final row = tt.rows.single;
      expect(row.timeSlot.id, 'ts-1');
      // MON occupée, TUE libre (null), autres jours absents -> null aussi.
      expect(row.cellFor(Weekday.mon), isNotNull);
      expect(row.cellFor(Weekday.tue), isNull);
      expect(row.cellFor(Weekday.wed), isNull);
    });

    test('grille classe : classroomId renseigné, teacherId null', () {
      final json = <String, dynamic>{
        'academicYearId': 'ay-1',
        'teacherId': null,
        'classroomId': 'class-1',
        'days': ['MON'],
        'rows': <dynamic>[],
      };

      final tt = WeeklyTimetableModel.fromJson(json).toEntity();

      expect(tt.classroomId, 'class-1');
      expect(tt.teacherId, isNull);
      expect(tt.rows, isEmpty);
    });

    test('listes absentes -> vides (défensif)', () {
      final json = <String, dynamic>{'academicYearId': 'ay-1'};

      final tt = WeeklyTimetableModel.fromJson(json).toEntity();

      expect(tt.days, isEmpty);
      expect(tt.rows, isEmpty);
    });
  });
}
