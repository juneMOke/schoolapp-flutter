import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';

class EnrollmentStepperFlowState extends Equatable {
  final int currentStep;
  final int totalSteps;
  final Map<int, StepFormState> stepStates;

  const EnrollmentStepperFlowState({
    required this.currentStep,
    required this.totalSteps,
    required this.stepStates,
  });

  factory EnrollmentStepperFlowState.initial({
    required int totalSteps,
    required Map<int, StepFormState> initialStepStates,
  }) {
    return EnrollmentStepperFlowState(
      currentStep: 0,
      totalSteps: totalSteps,
      stepStates: Map<int, StepFormState>.from(initialStepStates),
    );
  }

  StepFormState stateOf(int step) {
    return EnrollmentStepperStateHelper.stateForStep(stepStates, step);
  }

  bool get isLast => currentStep == totalSteps - 1;

  bool get showSaveAction =>
      EnrollmentStepperStateHelper.isSaveEnabledStep(currentStep);

  bool get canSave => EnrollmentStepperStateHelper.canSaveForStep(
    currentStep: currentStep,
    stepStates: stepStates,
  );

  bool get canContinue => EnrollmentStepperStateHelper.canContinueForStep(
    currentStep: currentStep,
    stepStates: stepStates,
  );

  EnrollmentStepperFlowState copyWith({
    int? currentStep,
    int? totalSteps,
    Map<int, StepFormState>? stepStates,
  }) {
    return EnrollmentStepperFlowState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      stepStates: stepStates ?? this.stepStates,
    );
  }

  @override
  List<Object?> get props => <Object?>[currentStep, totalSteps, stepStates];
}
