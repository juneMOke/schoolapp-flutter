import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_school_detail_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/student/data/models/parent_summary_model.dart';
import 'package:school_app_flutter/features/student/data/models/student_detail_model.dart';

void main() {
  group('JSON parsing resilience', () {
    test('StudentDetailModel.fromJson replaces null strings with empty strings', () {
      final model = StudentDetailModel.fromJson(<String, dynamic>{
        'id': null,
        'firstName': null,
        'lastName': null,
        'surname': null,
        'dateOfBirth': null,
        'gender': null,
        'birthPlace': null,
        'nationality': null,
        'photoUrl': null,
        'city': null,
        'district': null,
        'municipality': null,
        'address': null,
        'schoolLevelId': null,
        'schoolLevelGroupId': null,
        'parentIds': <dynamic>['p1', 2, null],
      });

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
      expect(model.parentIds, <String>['p1', '2', '']);
    });

    test('ParentSummaryModel.fromJson replaces null strings with empty strings', () {
      final model = ParentSummaryModel.fromJson(<String, dynamic>{
        'id': null,
        'firstName': null,
        'lastName': null,
        'surname': null,
        'identificationNumber': null,
        'phoneNumber': null,
        'email': null,
        'relationshipType': null,
      });

      expect(model.id, '');
      expect(model.firstName, '');
      expect(model.lastName, '');
      expect(model.surname, '');
      expect(model.identificationNumber, '');
      expect(model.phoneNumber, '');
      expect(model.email, '');
      expect(model.relationshipType, '');
    });

    test('EnrollmentSchoolDetailModel.fromJson handles null and mixed scalar types', () {
      final model = EnrollmentSchoolDetailModel.fromJson(<String, dynamic>{
        'id': null,
        'status': null,
        'academicYearId': null,
        'enrollmentCode': null,
        'previousSchoolName': null,
        'previousAcademicYear': null,
        'previousSchoolLevelGroup': null,
        'previousSchoolLevel': null,
        'previousRate': '12.5',
        'previousRank': '7',
        'validatedPreviousYear': 'true',
        'schoolLevelGroupId': null,
        'schoolLevelId': null,
        'transferReason': null,
        'cancellationReason': null,
      });

      expect(model.id, '');
      expect(model.status, EnrollmentStatus.pending);
      expect(model.academicYearId, '');
      expect(model.enrollmentCode, '');
      expect(model.previousSchoolName, '');
      expect(model.previousAcademicYear, '');
      expect(model.previousSchoolLevelGroup, '');
      expect(model.previousSchoolLevel, '');
      expect(model.previousRate, 12.5);
      expect(model.previousRank, 7);
      expect(model.validatedPreviousYear, isTrue);
      expect(model.schoolLevelGroupId, '');
      expect(model.schoolLevelId, '');
      expect(model.transferReason, '');
      expect(model.cancellationReason, '');
    });
  });
}
