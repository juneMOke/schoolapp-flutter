import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/previous_academic_info_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousAcademicStepHandler extends BaseEnrollmentStepHandler {
  final EnrollmentStepSubmitController controller;

  PreviousAcademicStepHandler({required this.controller});

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.previousAcademic;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.previousYear;

  @override
  String subtitle(AppLocalizations l10n) => l10n.stepAcademicPreviousSubtitle;

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    return context.savingNow ? l10n.savingAcademicInfo : l10n.saveAcademicInfo;
  }

  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return StepFormState(
      dirty: false,
      saving: false,
      valid: EnrollmentStepperStateHelper.isAcademicPreviousInfoValid(
        context.detail.enrollmentDetail,
      ),
    );
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    return validateRequiredAndSaved(
      context: context,
      invalidHint: context.l10n.validateAcademicInfoHint,
      dirtyHint: context.l10n.academicInfoSaveHintBeforeContinue,
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
    return PreviousAcademicInfoStep(
      enrollmentDetail: context.detail.enrollmentDetail,
      enrollmentId: context.detail.enrollmentDetail.id,
      showInlineSaveButton: false,
      flowStepIndex: step.index,
      onRefreshRequested: context.onRefreshRequested,
      isEditable: context.detailPolicy.isStepEditable(step),
      stepController: controller,
    );
  }
}
