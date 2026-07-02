import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/models/timetable_cell_model.dart';

void main() {
  group('TimetableCellModel.fromJson + toEntity', () {
    test('mappe tous les libellés dénormalisés', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'coursId': 'cours-1',
        'classroomId': 'class-1',
        'classroomLabel': '6ème A',
        'teacherId': 'teacher-1',
        'teacherLabel': 'M. Dupont',
        'subjectLabel': 'Mathématiques',
        'room': 'Salle 101',
      };

      final entity = TimetableCellModel.fromJson(json).toEntity();

      expect(entity.sessionId, 'sess-1');
      expect(entity.coursId, 'cours-1');
      expect(entity.classroomId, 'class-1');
      expect(entity.classroomLabel, '6ème A');
      expect(entity.teacherId, 'teacher-1');
      expect(entity.teacherLabel, 'M. Dupont');
      expect(entity.subjectLabel, 'Mathématiques');
      expect(entity.room, 'Salle 101');
    });

    test('room absent -> null', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-2',
        'coursId': 'cours-2',
        'classroomId': 'class-2',
        'classroomLabel': '5ème B',
        'teacherId': 'teacher-2',
        'teacherLabel': 'Mme Martin',
        'subjectLabel': 'Français',
      };

      final entity = TimetableCellModel.fromJson(json).toEntity();

      expect(entity.room, isNull);
    });
  });
}
