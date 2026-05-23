import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address_step.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AddressStepHandler extends BaseEnrollmentStepHandler {
  final EnrollmentStepSubmitController controller;

  AddressStepHandler({required this.controller});

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.address;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.address;

  @override
  String subtitle(AppLocalizations l10n) => l10n.stepAddressSubtitle;

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    return context.savingNow ? l10n.savingAddress : l10n.saveAddress;
  }

  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return StepFormState(
      dirty: false,
      saving: false,
      valid: EnrollmentStepperStateHelper.isAddressValid(context.detail.studentDetail),
    );
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    return validateRequiredAndSaved(
      context: context,
      invalidHint: context.l10n.validateAddressHint,
      dirtyHint: context.l10n.addressSaveHintBeforeContinue,
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
    return AddressStep(
      studentDetail: context.detail.studentDetail,
      enrollmentId: context.detail.enrollmentDetail.id,
      showInlineSaveButton: false,
      flowStepIndex: step.index,
      onRefreshRequested: context.onRefreshRequested,
      isEditable: context.detailPolicy.isStepEditable(step),
      stepController: controller,
    );
  }
}
