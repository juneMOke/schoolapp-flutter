import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';

class EnrollmentStepValidationResult extends Equatable {
  final bool isValid;
  final EnrollmentStepValidationIssue? issue;

  const EnrollmentStepValidationResult._({
    required this.isValid,
    required this.issue,
  });

  const EnrollmentStepValidationResult.valid()
      : this._(isValid: true, issue: null);

  const EnrollmentStepValidationResult.invalid(this.issue)
      : isValid = false;

  @override
  List<Object?> get props => <Object?>[isValid, issue];
}

enum EnrollmentStepValidationIssue {
  personalInfoIncomplete,
  personalInfoNeedsSave,
  addressIncomplete,
  addressNeedsSave,
  academicInfoIncomplete,
  academicInfoNeedsSave,
  studentChargesIncomplete,
  studentChargesNeedsSave,
  guardianInfoIncomplete,
  guardianInfoNeedsSave,
}

class EnrollmentStepValidator {
  const EnrollmentStepValidator._();

  static EnrollmentStepValidationResult validate({
    required EnrollmentWizardStep step,
    required StepFormState state,
    required bool isEditable,
  }) {
    return switch (step) {
      EnrollmentWizardStep.personalInfo => _validateWithState(
          state: state,
          incompleteIssue: EnrollmentStepValidationIssue.personalInfoIncomplete,
          needsSaveIssue: EnrollmentStepValidationIssue.personalInfoNeedsSave,
          isEditable: isEditable,
        ),
      EnrollmentWizardStep.address => _validateWithState(
          state: state,
          incompleteIssue: EnrollmentStepValidationIssue.addressIncomplete,
          needsSaveIssue: EnrollmentStepValidationIssue.addressNeedsSave,
          isEditable: isEditable,
        ),
      EnrollmentWizardStep.previousAcademic => _validateWithState(
          state: state,
          incompleteIssue: EnrollmentStepValidationIssue.academicInfoIncomplete,
          needsSaveIssue: EnrollmentStepValidationIssue.academicInfoNeedsSave,
          isEditable: isEditable,
        ),
      EnrollmentWizardStep.targetAcademic => _validateWithState(
          state: state,
          incompleteIssue: EnrollmentStepValidationIssue.academicInfoIncomplete,
          needsSaveIssue: EnrollmentStepValidationIssue.academicInfoNeedsSave,
          isEditable: isEditable,
        ),
      EnrollmentWizardStep.studentCharges => _validateWithState(
          state: state,
          incompleteIssue:
              EnrollmentStepValidationIssue.studentChargesIncomplete,
          needsSaveIssue: EnrollmentStepValidationIssue.studentChargesNeedsSave,
          isEditable: isEditable,
        ),
      EnrollmentWizardStep.guardian => _validateWithState(
          state: state,
          incompleteIssue: EnrollmentStepValidationIssue.guardianInfoIncomplete,
          needsSaveIssue: EnrollmentStepValidationIssue.guardianInfoNeedsSave,
          isEditable: isEditable,
        ),
      EnrollmentWizardStep.summary => const EnrollmentStepValidationResult.valid(),
    };
  }

  static EnrollmentStepValidationResult _validateWithState({
    required StepFormState state,
    required EnrollmentStepValidationIssue incompleteIssue,
    required EnrollmentStepValidationIssue needsSaveIssue,
    required bool isEditable,
  }) {
    if (!state.valid) {
      return EnrollmentStepValidationResult.invalid(incompleteIssue);
    }
    if (isEditable && state.dirty) {
      return EnrollmentStepValidationResult.invalid(needsSaveIssue);
    }
    return const EnrollmentStepValidationResult.valid();
  }
}
