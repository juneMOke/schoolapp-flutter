import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';

sealed class EnrollmentStepperFlowEvent extends Equatable {
  const EnrollmentStepperFlowEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class EnrollmentStepperCurrentStepChanged extends EnrollmentStepperFlowEvent {
  final int step;

  const EnrollmentStepperCurrentStepChanged(this.step);

  @override
  List<Object?> get props => <Object?>[step];
}

class EnrollmentStepperStepStateReported extends EnrollmentStepperFlowEvent {
  final int step;
  final StepFormState stepState;

  const EnrollmentStepperStepStateReported({
    required this.step,
    required this.stepState,
  });

  @override
  List<Object?> get props => <Object?>[step, stepState];
}

class EnrollmentStepperStatesSynced extends EnrollmentStepperFlowEvent {
  final Map<int, StepFormState> states;

  const EnrollmentStepperStatesSynced(this.states);

  @override
  List<Object?> get props => <Object?>[states];
}
