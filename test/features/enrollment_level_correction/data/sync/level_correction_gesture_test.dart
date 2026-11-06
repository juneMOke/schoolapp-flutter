import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/sync/level_correction_gesture.dart';

void main() {
  const gesture = LevelCorrectionGesture(
    id: 'g-1',
    enrollmentId: 'enr-1',
    studentId: 'stu-1',
    academicYearId: 'year-1',
    fromSchoolLevelId: 'lvl-m2',
    toSchoolLevelId: 'lvl-p2',
    toSchoolLevelGroupId: 'grp-primaire',
    toClassroomId: 'cls-p2a',
    reason: 'Erreur de saisie au guichet',
    correctedAt: '2026-11-06T10:15:00.000Z',
    authorId: 'user-1',
  );

  group('LevelCorrectionGesture', () {
    test('le corps sur le fil suit le contrat : le fait sous `correction`, '
        "l'auteur à côté", () {
      expect(gesture.toWire(), {
        'correction': {
          'id': 'g-1',
          'enrollmentId': 'enr-1',
          'fromSchoolLevelId': 'lvl-m2',
          'toSchoolLevelId': 'lvl-p2',
          'toSchoolLevelGroupId': 'grp-primaire',
          'toClassroomId': 'cls-p2a',
          'reason': 'Erreur de saisie au guichet',
          'correctedAt': '2026-11-06T10:15:00.000Z',
        },
        kOutboxAuthorIdKey: 'user-1',
      });
    });

    test('ni élève ni année ne partent sur le fil', () {
      final correction = gesture.toWire()['correction']! as Map;
      expect(correction.containsKey('studentId'), isFalse);
      expect(correction.containsKey('academicYearId'), isFalse);
    });

    test('sans classe cible, `toClassroomId` part explicitement à null', () {
      const noClass = LevelCorrectionGesture(
        id: 'g-2',
        enrollmentId: 'enr-1',
        studentId: 'stu-1',
        academicYearId: 'year-1',
        fromSchoolLevelId: 'lvl-m2',
        toSchoolLevelId: 'lvl-p2',
        toSchoolLevelGroupId: 'grp-primaire',
        reason: 'Motif',
        correctedAt: '2026-11-06T10:15:00.000Z',
        authorId: 'user-1',
      );
      final correction = noClass.toWire()['correction']! as Map;
      expect(correction.containsKey('toClassroomId'), isTrue);
      expect(correction['toClassroomId'], isNull);
    });

    test("relu de l'outbox, le geste revient à l'identique", () {
      final stored = jsonDecode(jsonEncode(gesture.toJson()));
      expect(LevelCorrectionGesture.tryParse(stored), gesture);
    });

    test("l'auteur est rangé à la racine, là où le socle le lit", () {
      expect(gesture.toJson()[kOutboxAuthorIdKey], 'user-1');
    });

    for (final field in [
      'id',
      'enrollmentId',
      'studentId',
      'academicYearId',
      'fromSchoolLevelId',
      'toSchoolLevelId',
      'toSchoolLevelGroupId',
      'reason',
      'correctedAt',
      kOutboxAuthorIdKey,
    ]) {
      test('sans `$field`, l\'entrée est illisible', () {
        final json = Map<String, Object?>.of(gesture.toJson())..remove(field);
        expect(LevelCorrectionGesture.tryParse(json), isNull);
      });
    }

    test('un motif blanc vaut un motif absent', () {
      final json = Map<String, Object?>.of(gesture.toJson())..['reason'] = '  ';
      expect(LevelCorrectionGesture.tryParse(json), isNull);
    });

    test("ce qui n'est pas un objet ne se lit pas", () {
      expect(LevelCorrectionGesture.tryParse('g-1'), isNull);
      expect(LevelCorrectionGesture.tryParse(null), isNull);
    });
  });
}
