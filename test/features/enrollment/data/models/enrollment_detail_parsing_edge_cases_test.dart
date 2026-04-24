import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_school_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/student/data/models/parent_summary_model.dart';
import 'package:school_app_flutter/features/student/data/models/student_detail_model.dart';

void main() {
  group('StudentDetailModel.fromJson edge cases', () {
    test('handles empty payload with safe defaults', () {
      final model = StudentDetailModel.fromJson(<String, dynamic>{});

      expect(model.id, '');
      expect(model.firstName, '');
      expect(model.lastName, '');
      expect(model.surname, '');
      expect(model.dateOfBirth, '');
      expect(model.gender, '');
      expect(model.birthPlace, '');
      expect(model.nationality, '');
      expect(model.photoUrl, '');
      expect(model.city, '');
      expect(model.district, '');
      expect(model.municipality, '');
      expect(model.address, '');
      expect(model.schoolLevelId, '');
      expect(model.schoolLevelGroupId, '');
      expect(model.parentIds, isEmpty);
    });

    test('handles unexpected field types without throwing', () {
      final model = StudentDetailModel.fromJson(<String, dynamic>{
        'id': 42,
        'firstName': true,
        'lastName': <String, dynamic>{'value': 'Doe'},
        'surname': <dynamic>['Jr'],
        'dateOfBirth': 20260101,
        'gender': <String, dynamic>{'code': 'MALE'},
        'birthPlace': false,
        'nationality': 225,
        'photoUrl': <String, dynamic>{'url': 'https://x.y'},
        'city': 1.5,
        'district': <dynamic>[1, 2],
        'municipality': <String, dynamic>{'name': 'Center'},
        'address': <String, dynamic>{'line': 'A'},
        'schoolLevelId': 9,
        'schoolLevelGroupId': true,
        'parentIds': 'not-a-list',
      });

      expect(model.id, '42');
      expect(model.firstName, 'true');
      expect(model.lastName, '{value: Doe}');
      expect(model.parentIds, isEmpty);
    });
  });

  group('ParentSummaryModel.fromJson edge cases', () {
    test('handles empty payload with safe defaults', () {
      final model = ParentSummaryModel.fromJson(<String, dynamic>{});

      expect(model.id, '');
      expect(model.firstName, '');
      expect(model.lastName, '');
      expect(model.surname, '');
      expect(model.identificationNumber, '');
      expect(model.phoneNumber, '');
      expect(model.email, '');
      expect(model.relationshipType, '');
    });

    test('handles unexpected field types without throwing', () {
      final model = ParentSummaryModel.fromJson(<String, dynamic>{
        'id': 10,
        'firstName': false,
        'lastName': <String, dynamic>{'v': 'Smith'},
        'surname': <dynamic>['Alias'],
        'identificationNumber': 9999,
        'phoneNumber': 237600000000,
        'email': <String, dynamic>{'value': 'x@y.z'},
        'relationshipType': 3,
      });

      expect(model.id, '10');
      expect(model.firstName, 'false');
      expect(model.lastName, '{v: Smith}');
      expect(model.relationshipType, '3');
    });
  });

  group('EnrollmentSchoolDetailModel.fromJson edge cases', () {
    test('handles empty payload with safe defaults', () {
      final model = EnrollmentSchoolDetailModel.fromJson(<String, dynamic>{});

      expect(model.id, '');
      expect(model.status, EnrollmentStatus.pending);
      expect(model.academicYearId, '');
      expect(model.enrollmentCode, '');
      expect(model.previousSchoolName, '');
      expect(model.previousAcademicYear, '');
      expect(model.previousSchoolLevelGroup, '');
      expect(model.previousSchoolLevel, '');
      expect(model.previousRate, 0);
      expect(model.previousRank, isNull);
      expect(model.validatedPreviousYear, isFalse);
      expect(model.schoolLevelGroupId, '');
      expect(model.schoolLevelId, '');
      expect(model.transferReason, '');
      expect(model.cancellationReason, '');
    });

    test('handles unexpected scalar types robustly', () {
      final model = EnrollmentSchoolDetailModel.fromJson(<String, dynamic>{
        'id': 99,
        'status': 'UNKNOWN_STATUS',
        'academicYearId': true,
        'enrollmentCode': 12345,
        'previousSchoolName': <String, dynamic>{'name': 'Legacy School'},
        'previousAcademicYear': <dynamic>[2024, 2025],
        'previousSchoolLevelGroup': 1,
        'previousSchoolLevel': false,
        'previousRate': <String, dynamic>{'rate': 12},
        'previousRank': <dynamic>[1, 2],
        'validatedPreviousYear': 'not-bool',
        'schoolLevelGroupId': <String, dynamic>{'id': 'g1'},
        'schoolLevelId': <String, dynamic>{'id': 'l1'},
        'transferReason': <String, dynamic>{'reason': 'moved'},
        'cancellationReason': <dynamic>['none'],
      });

      expect(model.id, '99');
      expect(model.status, EnrollmentStatus.pending);
      expect(model.previousRate, 0);
      expect(model.previousRank, isNull);
      expect(model.validatedPreviousYear, isFalse);
      expect(model.transferReason, '{reason: moved}');
      expect(model.cancellationReason, '[none]');
    });
  });
}
