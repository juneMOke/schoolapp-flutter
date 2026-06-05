import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/step_handlers/enrollment_step_handler.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_step_controller.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class StudentChargesStepHandler extends BaseEnrollmentStepHandler {
  final EnrollmentStepSubmitController controller;

  StudentChargesStepHandler({required this.controller});

  @override
  EnrollmentWizardStep get step => EnrollmentWizardStep.studentCharges;

  @override
  int get order => step.index;

  @override
  String title(AppLocalizations l10n) => l10n.studentChargesStepTitle;

  @override
  String subtitle(AppLocalizations l10n) => l10n.studentChargesStepSubtitle;

  @override
  String saveLabel(AppLocalizations l10n, SaveLabelContext context) {
    return context.savingNow
        ? l10n.studentChargesSavingAction
        : l10n.studentChargesSaveAction;
  }

  // Frais : étape en lecture seule (PARCOURS 21) — pas d'enregistrement ni
  // d'indicateur, uniquement « Continuer » (actif hors chargement).
  @override
  bool showSaveAction(HandlerFlowContext context) => false;

  @override
  StepFormState initialState(HandlerInitialStateContext context) {
    return const StepFormState(dirty: false, saving: false, valid: false);
  }

  @override
  StepValidationResult validate(HandlerValidationContext context) {
    if (!context.stepState.valid) {
      return StepValidationResult.invalid(
        hintKey: context.l10n.studentChargesSaveHintBeforeContinue,
        errorType: StepValidationErrorType.invalidForm,
      );
    }

    if (context.isEditable && context.stepState.dirty) {
      return StepValidationResult.invalid(
        hintKey: context.l10n.studentChargesSaveHintBeforeContinue,
        errorType: StepValidationErrorType.unsavedChanges,
      );
    }

    return const StepValidationResult.valid();
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
    return StudentChargesStep(
      studentId: resolveStudentId(context),
      levelId: resolveLevelId(context),
      enrollmentStatus: context.detail.enrollmentDetail.status,
      showInlineSaveButton: false,
      flowStepIndex: step.index,
      isEditable: false,
      stepController: controller,
    );
  }
}
