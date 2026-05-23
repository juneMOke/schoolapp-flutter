import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/relationship_type.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/address_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/guardian_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/personal_info_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/previous_academic_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/student_charges_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/summary_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/target_academic_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/presentation/bloc/student_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockEnrollmentBloc extends Mock implements EnrollmentBloc {}

class _MockFlowBloc extends Mock implements EnrollmentStepperFlowBloc {}

class _MockAppLocalizations extends Mock implements AppLocalizations {}

class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeDetailPolicy extends EnrollmentDetailPolicy {
  const _FakeDetailPolicy();

  @override
  EnrollmentDetail? detail(EnrollmentState state) => state.detail;

  @override
  bool isStepEditable(EnrollmentWizardStep step) => true;

  @override
  EnrollmentLoadStatus loadStatus(EnrollmentState state) => state.detailStatus;

  @override
  void requestLoad(
    EnrollmentBloc bloc,
    EnrollmentDetailIntent intent, {
    bool silent = false,
  }) {}

  @override
  void savePersonalInfo({
    required EnrollmentBloc enrollmentBloc,
    required StudentBloc studentBloc,
    required EnrollmentDetailIntent intent,
    required StudentDetail currentStudent,
    required EnrollmentPersonalInfoPayload payload,
  }) {}
}

void main() {
  final l10n = _mockL10n();
  const detailPolicy = _FakeDetailPolicy();
  const intent = EnrollmentDetailIntent.newFirstRegistration();
  final detail = EnrollmentDetail.empty();

  HandlerValidationContext buildValidationContext({
    required StepFormState stepState,
    bool isEditable = true,
  }) {
    return HandlerValidationContext(
      stepState: stepState,
      isEditable: isEditable,
      detail: detail,
      detailPolicy: detailPolicy,
      l10n: l10n,
    );
  }

  HandlerSubmitContext buildSubmitContext({
    EnrollmentState? enrollmentState,
    EnrollmentDetail? overrideDetail,
  }) {
    return HandlerSubmitContext(
      context: _FakeBuildContext(),
      enrollmentBloc: _MockEnrollmentBloc(),
      flowBloc: _MockFlowBloc(),
      enrollmentState: enrollmentState ?? const EnrollmentState.initial(),
      detail: overrideDetail ?? detail,
      intent: intent,
      detailPolicy: detailPolicy,
      l10n: l10n,
    );
  }

  group('Non-summary handlers', () {
    final specs = <({
      EnrollmentStepHandler Function(EnrollmentStepSubmitController controller)
      buildHandler,
      String title,
      String subtitle,
      String save,
      String saving,
      String invalidHint,
      String dirtyHint,
    })>[
      (
        buildHandler: (c) => PersonalInfoStepHandler(controller: c),
        title: 'personal-info',
        subtitle: 'subtitle-personal-info',
        save: 'save-personal',
        saving: 'saving-personal',
        invalidHint: 'hint-invalid-personal',
        dirtyHint: 'hint-dirty-personal',
      ),
      (
        buildHandler: (c) => AddressStepHandler(controller: c),
        title: 'address',
        subtitle: 'subtitle-address',
        save: 'save-address',
        saving: 'saving-address',
        invalidHint: 'hint-invalid-address',
        dirtyHint: 'hint-dirty-address',
      ),
      (
        buildHandler: (c) => PreviousAcademicStepHandler(controller: c),
        title: 'previous-academic',
        subtitle: 'subtitle-previous-academic',
        save: 'save-academic',
        saving: 'saving-academic',
        invalidHint: 'hint-invalid-academic',
        dirtyHint: 'hint-dirty-academic',
      ),
      (
        buildHandler: (c) => TargetAcademicStepHandler(controller: c),
        title: 'target-academic',
        subtitle: 'subtitle-target-academic',
        save: 'save-academic',
        saving: 'saving-academic',
        invalidHint: 'hint-invalid-academic',
        dirtyHint: 'hint-dirty-academic',
      ),
      (
        buildHandler: (c) => StudentChargesStepHandler(controller: c),
        title: 'student-charges',
        subtitle: 'subtitle-student-charges',
        save: 'save-charges',
        saving: 'saving-charges',
        invalidHint: 'hint-dirty-charges',
        dirtyHint: 'hint-dirty-charges',
      ),
      (
        buildHandler: (c) => GuardianStepHandler(controller: c),
        title: 'guardian',
        subtitle: 'subtitle-guardian',
        save: 'save-guardian',
        saving: 'saving-guardian',
        invalidHint: 'hint-invalid-guardian',
        dirtyHint: 'hint-dirty-personal',
      ),
    ];

    for (final spec in specs) {
      test('label/saveLabel/validate/submit for ${spec.title}', () async {
        final controller = EnrollmentStepSubmitController();
        final handler = spec.buildHandler(controller);

        expect(handler.title(l10n), spec.title);
        expect(handler.subtitle(l10n), spec.subtitle);
        expect(
          handler.saveLabel(
            l10n,
            const SaveLabelContext(
              savingNow: false,
              isEnrollmentAlreadyCompleted: false,
              enrollmentState: EnrollmentState.initial(),
            ),
          ),
          spec.save,
        );
        expect(
          handler.saveLabel(
            l10n,
            const SaveLabelContext(
              savingNow: true,
              isEnrollmentAlreadyCompleted: false,
              enrollmentState: EnrollmentState.initial(),
            ),
          ),
          spec.saving,
        );

        final invalidResult = handler.validate(
          buildValidationContext(
            stepState: const StepFormState(dirty: false, valid: false, saving: false),
          ),
        );
        expect(invalidResult.valid, isFalse);
        expect(invalidResult.hintKey, spec.invalidHint);

        final dirtyResult = handler.validate(
          buildValidationContext(
            stepState: const StepFormState(dirty: true, valid: true, saving: false),
          ),
        );
        expect(dirtyResult.valid, isFalse);
        expect(dirtyResult.hintKey, spec.dirtyHint);

        final noopSubmit = await handler.submit(buildSubmitContext());
        expect(noopSubmit.status, StepSubmitStatus.noop);

        var submitted = false;
        controller.bind(() => submitted = true);
        final dispatchedSubmit = await handler.submit(buildSubmitContext());
        expect(dispatchedSubmit.status, StepSubmitStatus.dispatched);
        expect(submitted, isTrue);
      });
    }
  });

  group('SummaryStepHandler', () {
    test('label/saveLabel/validate + blocked/dispatched submit', () async {
      final handler = SummaryStepHandler();

      expect(handler.title(l10n), 'summary');
      expect(handler.subtitle(l10n), 'subtitle-summary');
      expect(
        handler.saveLabel(
          l10n,
          const SaveLabelContext(
            savingNow: false,
            isEnrollmentAlreadyCompleted: false,
            enrollmentState: EnrollmentState.initial(),
          ),
        ),
        'validate-enrollment',
      );

      final validation = handler.validate(
        buildValidationContext(
          stepState: const StepFormState(dirty: true, valid: false, saving: false),
        ),
      );
      expect(validation.valid, isTrue);

      final blocked = await handler.submit(
        buildSubmitContext(
          enrollmentState: const EnrollmentState.initial().copyWith(
            statusUpdateStatus: EnrollmentLoadStatus.loading,
          ),
        ),
      );
      expect(blocked.status, StepSubmitStatus.blocked);

      final dispatched = await handler.submit(
        buildSubmitContext(
          overrideDetail: _buildDetail(enrollmentId: 'enrollment-1'),
        ),
      );
      expect(dispatched.status, StepSubmitStatus.dispatched);
    });
  });
}

EnrollmentDetail _buildDetail({
  required String enrollmentId,
  EnrollmentStatus status = EnrollmentStatus.inProgress,
}) {
  return EnrollmentDetail(
    studentDetail: const StudentDetail(
      id: 'student-1',
      firstName: 'John',
      lastName: 'Doe',
      surname: 'Junior',
      dateOfBirth: '2010-01-01',
      gender: Gender.male,
      birthPlace: 'Abidjan',
      nationality: 'ivoirienne',
      city: 'Abidjan',
      district: 'Cocody',
      municipality: 'Riviera',
      neighborhood: 'Riviera 2',
      address: 'Riviera 2, lot 10',
      schoolLevel: SchoolLevel(
        id: 'level-1',
        name: '6eme',
        code: '6E',
        displayOrder: 1,
        splitIntoClassrooms: false,
      ),
      schoolLevelGroup: SchoolLevelGroup(
        id: 'group-1',
        name: 'College',
        code: 'COL',
      ),
    ),
    parentDetails: const <ParentSummary>[
      ParentSummary(
        id: 'parent-1',
        firstName: 'Jane',
        lastName: 'Doe',
        surname: 'K',
        identificationNumber: 'ID-1',
        phoneNumber: '+22501020304',
        email: 'jane.doe@example.com',
        relationshipType: RelationshipType.mother,
      ),
    ],
    enrollmentDetail: EnrollmentSchoolDetail(
      id: enrollmentId,
      status: status,
      academicYearId: 'ay-1',
      enrollmentCode: 'ENR-1',
      previousSchoolName: 'School',
      previousAcademicYear: '2024-2025',
      previousSchoolLevelGroup: 'College',
      previousSchoolLevel: '5eme',
      previousRate: 12.0,
      previousRank: 5,
      validatedPreviousYear: true,
      schoolLevelGroupId: 'group-1',
      schoolLevelId: 'level-1',
    ),
  );
}

_MockAppLocalizations _mockL10n() {
  final l10n = _MockAppLocalizations();
  when(() => l10n.personalInformation).thenReturn('personal-info');
  when(() => l10n.stepPersonalInfoSubtitle).thenReturn('subtitle-personal-info');
  when(() => l10n.savingPersonalInfo).thenReturn('saving-personal');
  when(() => l10n.savePersonalInfo).thenReturn('save-personal');
  when(() => l10n.validatePersonalInfoHint).thenReturn('hint-invalid-personal');
  when(() => l10n.personalInfoSaveHintBeforeContinue).thenReturn('hint-dirty-personal');

  when(() => l10n.address).thenReturn('address');
  when(() => l10n.stepAddressSubtitle).thenReturn('subtitle-address');
  when(() => l10n.savingAddress).thenReturn('saving-address');
  when(() => l10n.saveAddress).thenReturn('save-address');
  when(() => l10n.validateAddressHint).thenReturn('hint-invalid-address');
  when(() => l10n.addressSaveHintBeforeContinue).thenReturn('hint-dirty-address');

  when(() => l10n.previousYear).thenReturn('previous-academic');
  when(() => l10n.stepAcademicPreviousSubtitle).thenReturn('subtitle-previous-academic');
  when(() => l10n.targetYear).thenReturn('target-academic');
  when(() => l10n.stepAcademicTargetSubtitle).thenReturn('subtitle-target-academic');
  when(() => l10n.savingAcademicInfo).thenReturn('saving-academic');
  when(() => l10n.saveAcademicInfo).thenReturn('save-academic');
  when(() => l10n.validateAcademicInfoHint).thenReturn('hint-invalid-academic');
  when(() => l10n.academicInfoSaveHintBeforeContinue).thenReturn('hint-dirty-academic');

  when(() => l10n.studentChargesStepTitle).thenReturn('student-charges');
  when(() => l10n.studentChargesStepSubtitle).thenReturn('subtitle-student-charges');
  when(() => l10n.studentChargesSavingAction).thenReturn('saving-charges');
  when(() => l10n.studentChargesSaveAction).thenReturn('save-charges');
  when(() => l10n.studentChargesSaveHintBeforeContinue).thenReturn('hint-dirty-charges');

  when(() => l10n.guardianInformation).thenReturn('guardian');
  when(() => l10n.stepGuardianSubtitle).thenReturn('subtitle-guardian');
  when(() => l10n.savingGuardianInfo).thenReturn('saving-guardian');
  when(() => l10n.saveGuardianInfo).thenReturn('save-guardian');
  when(() => l10n.validateGuardianInfoHint).thenReturn('hint-invalid-guardian');

  when(() => l10n.summary).thenReturn('summary');
  when(() => l10n.stepSummarySubtitle).thenReturn('subtitle-summary');
  when(() => l10n.goToFirstRegistration).thenReturn('go-first-registration');
  when(() => l10n.validatingEnrollment).thenReturn('validating-enrollment');
  when(() => l10n.validateEnrollment).thenReturn('validate-enrollment');

  return l10n;
}
