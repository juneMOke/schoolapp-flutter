import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PersonalInfoStepHandler extends BaseEnrollmentStepHandler {
  final EnrollmentStepSubmitController controller;

  PersonalInfoStepHandler({required this.controller});

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.personalInfo;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.personalInformation;

  // Sous-titre retiré : il faisait doublon avec le titre « Informations
  // personnelles ». StepPageCard masque un sous-titre vide.
  @override
  String subtitle(AppLocalizations l10n) => '';

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    return context.savingNow ? l10n.savingPersonalInfo : l10n.savePersonalInfo;
  }

  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return StepFormState(
      dirty: false,
      saving: false,
      valid: EnrollmentStepperStateHelper.isPersonalInfoValid(
        context.detail.studentDetail,
      ),
    );
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    return validateRequiredAndSaved(
      context: context,
      invalidHint: context.l10n.validatePersonalInfoHint,
      dirtyHint: context.l10n.personalInfoSaveHintBeforeContinue,
    );
  }

  @override
  Future<StepSubmitResult> submit(HandlerSubmitContext context) async {
    if (!controller.isBound) {
      return const StepSubmitResult.noop();
    }
    controller.submitForm();
    return const StepSubmitResult.dispatched();
  }

  @override
  Widget buildContent(HandlerBuildContext context) {
    return PersonalInfoStep(
      studentDetail: context.detail.studentDetail,
      enrollmentId: context.detail.enrollmentDetail.id,
      detailIntent: context.intent,
      detailPolicy: context.detailPolicy,
      showInlineSaveButton: false,
      flowStepIndex: step.index,
      onRefreshRequested: context.onRefreshRequested,
      isEditable: context.detailPolicy.isStepEditable(step),
      stepController: controller,
    );
  }
}
