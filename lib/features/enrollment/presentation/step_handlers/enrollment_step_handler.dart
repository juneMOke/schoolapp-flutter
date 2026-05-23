import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SaveLabelContext {
  final bool savingNow;
  final bool isEnrollmentAlreadyCompleted;
  final EnrollmentState enrollmentState;

  const SaveLabelContext({
    required this.savingNow,
    required this.isEnrollmentAlreadyCompleted,
    required this.enrollmentState,
  });
}

class HandlerPolicyContext {
  final EnrollmentDetail detail;
  final EnrollmentDetailIntent intent;
  final EnrollmentDetailPolicy detailPolicy;

  const HandlerPolicyContext({
    required this.detail,
    required this.intent,
    required this.detailPolicy,
  });
}

class HandlerFlowContext {
  final EnrollmentStepperFlowState flowState;
  final int currentStepIndex;
  final EnrollmentWizardStep currentStep;
  final StepFormState currentStepState;
  final bool isStatusUpdateLoading;
  final EnrollmentDetail detail;
  final EnrollmentDetailIntent intent;
  final EnrollmentDetailPolicy detailPolicy;

  const HandlerFlowContext({
    required this.flowState,
    required this.currentStepIndex,
    required this.currentStep,
    required this.currentStepState,
    required this.isStatusUpdateLoading,
    required this.detail,
    required this.intent,
    required this.detailPolicy,
  });
}

class HandlerValidationContext {
  final StepFormState stepState;
  final bool isEditable;
  final EnrollmentDetail detail;
  final EnrollmentDetailPolicy detailPolicy;
  final AppLocalizations l10n;

  const HandlerValidationContext({
    required this.stepState,
    required this.isEditable,
    required this.detail,
    required this.detailPolicy,
    required this.l10n,
  });
}

class HandlerContinueContext {
  final HandlerFlowContext flow;
  final HandlerValidationContext validation;

  const HandlerContinueContext({
    required this.flow,
    required this.validation,
  });
}

class HandlerSubmitContext {
  final BuildContext context;
  final EnrollmentBloc enrollmentBloc;
  final EnrollmentStepperFlowBloc flowBloc;
  final EnrollmentState enrollmentState;
  final EnrollmentDetail detail;
  final EnrollmentDetailIntent intent;
  final EnrollmentDetailPolicy detailPolicy;
  final AppLocalizations l10n;

  const HandlerSubmitContext({
    required this.context,
    required this.enrollmentBloc,
    required this.flowBloc,
    required this.enrollmentState,
    required this.detail,
    required this.intent,
    required this.detailPolicy,
    required this.l10n,
  });
}

class HandlerBuildContext {
  final EnrollmentDetail detail;
  final EnrollmentDetailIntent intent;
  final EnrollmentDetailPolicy detailPolicy;
  final VoidCallback onRefreshRequested;
  final ValueChanged<int> onSummaryEditRequested;

  const HandlerBuildContext({
    required this.detail,
    required this.intent,
    required this.detailPolicy,
    required this.onRefreshRequested,
    required this.onSummaryEditRequested,
  });
}

class HandlerInitialStateContext {
  final EnrollmentDetail detail;

  const HandlerInitialStateContext({required this.detail});
}

enum StepValidationErrorType {
  invalidForm,
  unsavedChanges,
  unsupported,
}

class StepValidationResult {
  final bool valid;
  final String? hintKey;
  final StepValidationErrorType? errorType;

  const StepValidationResult._({
    required this.valid,
    required this.hintKey,
    required this.errorType,
  });

  const StepValidationResult.valid()
      : this._(valid: true, hintKey: null, errorType: null);

  const StepValidationResult.invalid({
    this.hintKey,
    required this.errorType,
  }) : valid = false;
}

enum StepSubmitStatus {
  noop,
  dispatched,
  blocked,
  completed,
}

class StepSubmitResult {
  final StepSubmitStatus status;
  final String? infoKey;
  final String? errorKey;
  final bool consumeNavigation;

  const StepSubmitResult._({
    required this.status,
    required this.infoKey,
    required this.errorKey,
    required this.consumeNavigation,
  });

  const StepSubmitResult.noop()
      : this._(
          status: StepSubmitStatus.noop,
          infoKey: null,
          errorKey: null,
          consumeNavigation: false,
        );

  const StepSubmitResult.dispatched({bool consumeNavigation = false})
      : this._(
          status: StepSubmitStatus.dispatched,
          infoKey: null,
          errorKey: null,
          consumeNavigation: consumeNavigation,
        );

  const StepSubmitResult.blocked({
    this.infoKey,
    this.errorKey,
    this.consumeNavigation = false,
  }) : status = StepSubmitStatus.blocked;

  const StepSubmitResult.completed({
    this.infoKey,
    this.consumeNavigation = true,
  }) : status = StepSubmitStatus.completed,
       errorKey = null;
}

enum StepContinueStatus {
  advance,
  blocked,
  completed,
}

class StepContinueResult {
  final StepContinueStatus status;
  final int? nextStepIndex;
  final String? hintKey;

  const StepContinueResult._({
    required this.status,
    required this.nextStepIndex,
    required this.hintKey,
  });

  const StepContinueResult.advance(int nextStepIndex)
      : this._(
          status: StepContinueStatus.advance,
          nextStepIndex: nextStepIndex,
          hintKey: null,
        );

  const StepContinueResult.blocked({this.hintKey})
      : status = StepContinueStatus.blocked,
        nextStepIndex = null;

  const StepContinueResult.completed({this.hintKey})
      : status = StepContinueStatus.completed,
        nextStepIndex = null;
}

abstract class EnrollmentStepHandler {
  EnrollmentWizardStep get step;
  int get order;

  String title(AppLocalizations l10n);
  String subtitle(AppLocalizations l10n);
  String saveLabel(AppLocalizations l10n, SaveLabelContext context);

  bool get isSummaryStep => step == EnrollmentWizardStep.summary;

  bool isSavingNow(HandlerFlowContext context) {
    return isSummaryStep
        ? context.isStatusUpdateLoading
        : context.currentStepState.saving;
  }

  bool canSave(HandlerFlowContext context) {
    final canSaveStep = context.detailPolicy.canSaveStep(step);
    if (!canSaveStep) {
      return false;
    }

    if (isSummaryStep) {
      return !context.isStatusUpdateLoading;
    }

    return context.flowState.canSave;
  }

  bool showSaveAction(HandlerFlowContext context) {
    return context.flowState.showSaveAction &&
        context.detailPolicy.canSaveStep(step);
  }

  bool canContinue(HandlerFlowContext context) => context.flowState.canContinue;

  StepFormState initialState(HandlerInitialStateContext context) {
    return const StepFormState(dirty: false, saving: false, valid: false);
  }

  StepValidationResult validate(HandlerValidationContext context);

  StepContinueResult continueFlow(HandlerContinueContext context) {
    final validationResult = validate(context.validation);
    if (!validationResult.valid) {
      return StepContinueResult.blocked(hintKey: validationResult.hintKey);
    }

    if (context.flow.flowState.isLast) {
      return StepContinueResult.completed(
        hintKey: context.validation.l10n.enrollmentReadyForValidation,
      );
    }

    return StepContinueResult.advance(context.flow.currentStepIndex + 1);
  }

  Future<StepSubmitResult> submit(HandlerSubmitContext context);

  Widget buildContent(HandlerBuildContext context);
}

abstract class BaseEnrollmentStepHandler extends EnrollmentStepHandler {
  StepValidationResult validateRequiredAndSaved({
    required HandlerValidationContext context,
    required String invalidHint,
    required String dirtyHint,
  }) {
    if (!context.stepState.valid) {
      return StepValidationResult.invalid(
        hintKey: invalidHint,
        errorType: StepValidationErrorType.invalidForm,
      );
    }

    if (context.isEditable && context.stepState.dirty) {
      return StepValidationResult.invalid(
        hintKey: dirtyHint,
        errorType: StepValidationErrorType.unsavedChanges,
      );
    }

    return const StepValidationResult.valid();
  }

  String resolveStudentId(HandlerBuildContext context) {
    final detailStudentId = context.detail.studentDetail.id.trim();
    if (detailStudentId.isNotEmpty) {
      return detailStudentId;
    }

    return context.intent.studentId?.trim() ?? '';
  }

  String resolveLevelId(HandlerBuildContext context) {
    final enrollmentLevelId = context.detail.enrollmentDetail.schoolLevelId.trim();
    if (enrollmentLevelId.isNotEmpty) {
      return enrollmentLevelId;
    }

    return context.detail.studentDetail.schoolLevel.id.trim();
  }
}
