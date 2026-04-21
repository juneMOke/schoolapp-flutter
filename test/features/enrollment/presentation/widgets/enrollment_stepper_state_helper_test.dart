import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

void main() {
  group('EnrollmentStepperStateHelper', () {
    test(
      'isPersonalInfoValid retourne true quand les champs requis sont remplis',
      () {
        final student = _buildStudentDetail();

        final result = EnrollmentStepperStateHelper.isPersonalInfoValid(
          student,
        );

        expect(result, isTrue);
      },
    );

    test('isPersonalInfoValid retourne false quand firstName est vide', () {
      final student = _buildStudentDetail(firstName: '   ');

      final result = EnrollmentStepperStateHelper.isPersonalInfoValid(student);

      expect(result, isFalse);
    });

    test('isAddressValid retourne false quand address est vide', () {
      final student = _buildStudentDetail(address: '');

      final result = EnrollmentStepperStateHelper.isAddressValid(student);

      expect(result, isFalse);
    });

    test(
      'isAcademicInfoValid retourne true quand les champs requis sont remplis',
      () {
        final enrollment = _buildEnrollmentSchoolDetail();

        final result = EnrollmentStepperStateHelper.isAcademicInfoValid(
          enrollment,
        );

        expect(result, isTrue);
      },
    );

    test('isAcademicInfoValid retourne false quand schoolLevelId est vide', () {
      final enrollment = _buildEnrollmentSchoolDetail(schoolLevelId: ' ');

      final result = EnrollmentStepperStateHelper.isAcademicInfoValid(
        enrollment,
      );

      expect(result, isFalse);
    });

    test(
      'isAcademicInfoValid retourne false quand previousRank est absent',
      () {
        final enrollment = _buildEnrollmentSchoolDetail(previousRank: null);

        final result = EnrollmentStepperStateHelper.isAcademicInfoValid(
          enrollment,
        );

        expect(result, isFalse);
      },
    );

    test(
      'isAcademicPreviousInfoValid retourne false quand previousSchoolName est vide',
      () {
        final enrollment = _buildEnrollmentSchoolDetail(
          previousSchoolName: ' ',
        );

        final result = EnrollmentStepperStateHelper.isAcademicPreviousInfoValid(
          enrollment,
        );

        expect(result, isFalse);
      },
    );

    test(
      'isAcademicTargetInfoValid retourne false quand schoolLevelGroupId est vide',
      () {
        final enrollment = _buildEnrollmentSchoolDetail(
          schoolLevelGroupId: ' ',
        );

        final result = EnrollmentStepperStateHelper.isAcademicTargetInfoValid(
          enrollment,
        );

        expect(result, isFalse);
      },
    );

    test(
      'isGuardianInfoValid retourne true quand les champs requis sont remplis',
      () {
        final result = EnrollmentStepperStateHelper.isGuardianInfoValid(
          <ParentSummary>[_buildParentSummary()],
        );

        expect(result, isTrue);
      },
    );

    test('isGuardianInfoValid retourne false quand email est vide', () {
      final result = EnrollmentStepperStateHelper.isGuardianInfoValid(
        <ParentSummary>[_buildParentSummary(email: ' ')],
      );

      expect(result, isFalse);
    });

    test(
      'canContinueForStep step 0 retourne true quand personal info est valide, clean et non saving',
      () {
        final result = EnrollmentStepperStateHelper.canContinueForStep(
          currentStep: 0,
          stepStates: <int, StepFormState>{
            0: const StepFormState(dirty: false, valid: true, saving: false),
            1: const StepFormState(dirty: true, valid: false, saving: true),
            2: const StepFormState(dirty: true, valid: false, saving: true),
          },
        );

        expect(result, isTrue);
      },
    );

    test(
      'canContinueForStep step 2 retourne false quand academic info est dirty',
      () {
        final result = EnrollmentStepperStateHelper.canContinueForStep(
          currentStep: 2,
          stepStates: <int, StepFormState>{
            0: const StepFormState(dirty: false, valid: true, saving: false),
            1: const StepFormState(dirty: false, valid: true, saving: false),
            2: const StepFormState(dirty: true, valid: true, saving: false),
          },
        );

        expect(result, isFalse);
      },
    );

    test(
      'canContinueForStep retourne false pour un step sans etat explicite',
      () {
        final result = EnrollmentStepperStateHelper.canContinueForStep(
          currentStep: 4,
          stepStates: <int, StepFormState>{
            0: const StepFormState(dirty: true, valid: false, saving: true),
            1: const StepFormState(dirty: true, valid: false, saving: true),
            2: const StepFormState(dirty: true, valid: false, saving: true),
          },
        );

        expect(result, isFalse);
      },
    );

    test(
      'canContinueForStep step 4 retourne false quand guardian est valid mais dirty',
      () {
        final result = EnrollmentStepperStateHelper.canContinueForStep(
          currentStep: 4,
          stepStates: <int, StepFormState>{
            4: const StepFormState(dirty: true, valid: true, saving: false),
          },
        );

        expect(result, isFalse);
      },
    );

    test(
      'canContinueForStep step 4 retourne true quand guardian est valid et clean',
      () {
        final result = EnrollmentStepperStateHelper.canContinueForStep(
          currentStep: 4,
          stepStates: <int, StepFormState>{
            4: const StepFormState(dirty: false, valid: true, saving: false),
          },
        );

        expect(result, isTrue);
      },
    );

    test(
      'canSaveForStep step 1 retourne true quand address est dirty, valid et non saving',
      () {
        final result = EnrollmentStepperStateHelper.canSaveForStep(
          currentStep: 1,
          stepStates: <int, StepFormState>{
            0: const StepFormState(dirty: false, valid: true, saving: false),
            1: const StepFormState(dirty: true, valid: true, saving: false),
            2: const StepFormState(dirty: false, valid: true, saving: false),
          },
        );

        expect(result, isTrue);
      },
    );

    test(
      'canSaveForStep step 2 retourne false quand academic info est invalid',
      () {
        final result = EnrollmentStepperStateHelper.canSaveForStep(
          currentStep: 2,
          stepStates: <int, StepFormState>{
            0: const StepFormState(dirty: false, valid: true, saving: false),
            1: const StepFormState(dirty: false, valid: true, saving: false),
            2: const StepFormState(dirty: true, valid: false, saving: false),
          },
        );

        expect(result, isFalse);
      },
    );

    test('canSaveForStep retourne false pour un step non sauvegardable', () {
      final result = EnrollmentStepperStateHelper.canSaveForStep(
        currentStep: 5,
        stepStates: <int, StepFormState>{
          0: const StepFormState(dirty: true, valid: true, saving: false),
          1: const StepFormState(dirty: true, valid: true, saving: false),
          2: const StepFormState(dirty: true, valid: true, saving: false),
        },
      );

      expect(result, isFalse);
    });

    test(
      'canSaveForStep step 4 retourne true quand guardian est dirty, valid et non saving',
      () {
        final result = EnrollmentStepperStateHelper.canSaveForStep(
          currentStep: 4,
          stepStates: <int, StepFormState>{
            4: const StepFormState(dirty: true, valid: true, saving: false),
          },
        );

        expect(result, isTrue);
      },
    );
  });
}

StudentDetail _buildStudentDetail({
  String firstName = 'Jean',
  String lastName = 'Dupont',
  String surname = 'Jr',
  String birthPlace = 'Paris',
  String nationality = 'Francaise',
  String dateOfBirth = '2010-02-10',
  String city = 'Abidjan',
  String district = 'Cocody',
  String municipality = 'Riviera',
  String address = 'Riviera 2',
}) {
  return StudentDetail(
    id: 'student-1',
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    dateOfBirth: dateOfBirth,
    gender: Gender.male,
    birthPlace: birthPlace,
    nationality: nationality,
    city: city,
    district: district,
    municipality: municipality,
    address: address,
    schoolLevel: const SchoolLevel(
      id: 'level-1',
      name: '6eme',
      code: '6E',
      displayOrder: 1,
    ),
    schoolLevelGroup: const SchoolLevelGroup(
      id: 'group-1',
      name: 'College',
      code: 'COL',
    ),
    neighborhood: 'Riviera',
  );
}

EnrollmentSchoolDetail _buildEnrollmentSchoolDetail({
  String previousAcademicYear = '2024-2025',
  String previousSchoolName = 'College A',
  String previousSchoolLevelGroup = 'College',
  String previousSchoolLevel = '5eme',
  double previousRate = 12.5,
  int? previousRank = 10,
  String schoolLevelGroupId = 'group-1',
  String schoolLevelId = 'level-1',
}) {
  return EnrollmentSchoolDetail(
    id: 'enrollment-1',
    status: EnrollmentStatus.inProgress,
    academicYearId: 'ay-2025',
    enrollmentCode: 'ENR-001',
    previousSchoolName: previousSchoolName,
    previousAcademicYear: previousAcademicYear,
    previousSchoolLevelGroup: previousSchoolLevelGroup,
    previousSchoolLevel: previousSchoolLevel,
    previousRate: previousRate,
    previousRank: previousRank,
    validatedPreviousYear: true,
    schoolLevelGroupId: schoolLevelGroupId,
    schoolLevelId: schoolLevelId,
  );
}

ParentSummary _buildParentSummary({
  String firstName = 'Marie',
  String lastName = 'Dupont',
  String surname = 'K',
  String identificationNumber = 'ID-123',
  String phoneNumber = '+22501020304',
  String email = 'marie.dupont@example.com',
}) {
  return ParentSummary(
    id: 'parent-1',
    firstName: firstName,
    lastName: lastName,
    surname: surname,
    identificationNumber: identificationNumber,
    phoneNumber: phoneNumber,
    email: email,
    relationshipType: RelationshipType.mother,
  );
}
