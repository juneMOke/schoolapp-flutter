import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';

void main() {
  group('DisciplinaryStudentDetailIntent', () {
    const testIntent = DisciplinaryStudentDetailIntent(
      studentId: '123',
      studentFirstName: 'John',
      studentLastName: 'Doe',
      studentMiddleName: 'M',
      studentGender: 'M',
      academicYearId: 'year-2024',
      levelName: 'Grade 1',
      levelGroupName: 'Class A',
    );

    test('should create instance with all required fields', () {
      expect(testIntent.studentId, '123');
      expect(testIntent.studentFirstName, 'John');
      expect(testIntent.studentLastName, 'Doe');
      expect(testIntent.studentGender, 'M');
      expect(testIntent.academicYearId, 'year-2024');
    });

    test('should have correct props for equality', () {
      final intent1 = testIntent;
      final intent2 = testIntent;
      expect(intent1, equals(intent2));
    });

    test('hasDisplayContext should be true when names are not empty', () {
      expect(testIntent.hasDisplayContext, true);
    });

    test('hasDisplayContext should be false when firstName is empty', () {
      final intent = const DisciplinaryStudentDetailIntent(
        studentId: '123',
        studentFirstName: '',
        studentLastName: 'Doe',
        studentMiddleName: null,
        studentGender: 'M',
        academicYearId: 'year-2024',
        levelName: '',
        levelGroupName: '',
      );
      expect(intent.hasDisplayContext, false);
    });

    test('should create invalid intent with required IDs', () {
      final invalid = const DisciplinaryStudentDetailIntent.invalid(
        studentId: '123',
        academicYearId: 'year-2024',
      );
      expect(invalid.studentId, '123');
      expect(invalid.academicYearId, 'year-2024');
      expect(invalid.studentFirstName, '');
      expect(invalid.hasDisplayContext, false);
    });

    test('withRouteParams should preserve context data', () {
      final withParams = testIntent.withRouteParams(
        studentId: 'new-id',
        academicYearId: 'new-year',
      );
      expect(withParams.studentFirstName, 'John');
      expect(withParams.levelName, 'Grade 1');
      expect(withParams.studentId, 'new-id');
      expect(withParams.academicYearId, 'new-year');
    });

    test('fromRouteContext should extract extra when valid', () {
      final intent = DisciplinaryStudentDetailIntent.fromRouteContext(
        studentId: '123',
        academicYearId: 'year-2024',
        extra: testIntent,
      );
      expect(intent.studentFirstName, 'John');
      expect(intent.levelName, 'Grade 1');
    });

    test('fromRouteContext should create invalid intent when extra is null', () {
      final intent = DisciplinaryStudentDetailIntent.fromRouteContext(
        studentId: '123',
        academicYearId: 'year-2024',
        extra: null,
      );
      expect(intent.hasDisplayContext, false);
    });
  });
}
