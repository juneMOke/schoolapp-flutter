import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/data/models/session_model.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

void main() {
  group('SessionModel.fromJson + toEntity', () {
    test('mappe tous les champs, day wire -> Weekday', () {
      final json = <String, dynamic>{
        'id': 'sess-1',
        'academicYearId': 'ay-1',
        'coursId': 'cours-1',
        'timeSlotId': 'ts-1',
        'day': 'WED',
        'room': 'Salle 12',
        'teacherId': 'teacher-1',
        'classroomId': 'class-1',
        'teacherLabel': 'M. Dupont',
        'classroomLabel': '6ème A',
        'subjectLabel': 'Mathématiques',
      };

      final entity = SessionModel.fromJson(json).toEntity();

      expect(entity.id, 'sess-1');
      expect(entity.academicYearId, 'ay-1');
      expect(entity.coursId, 'cours-1');
      expect(entity.timeSlotId, 'ts-1');
      expect(entity.day, Weekday.wed);
      expect(entity.room, 'Salle 12');
      expect(entity.teacherId, 'teacher-1');
      expect(entity.classroomId, 'class-1');
      expect(entity.teacherLabel, 'M. Dupont');
      expect(entity.classroomLabel, '6ème A');
      expect(entity.subjectLabel, 'Mathématiques');
    });

    test('room absent -> null ; day inconnu -> repli mon', () {
      final json = <String, dynamic>{
        'id': 'sess-2',
        'academicYearId': 'ay-1',
        'coursId': 'cours-2',
        'timeSlotId': 'ts-2',
        'day': 'SUN',
        'teacherId': 'teacher-2',
        'classroomId': 'class-2',
        'teacherLabel': 'Mme Martin',
        'classroomLabel': '5ème B',
        'subjectLabel': 'Français',
      };

      final entity = SessionModel.fromJson(json).toEntity();

      expect(entity.room, isNull);
      expect(entity.day, Weekday.mon);
    });
  });
}
