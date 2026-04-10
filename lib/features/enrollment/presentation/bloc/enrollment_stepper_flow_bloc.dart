import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';

class EnrollmentStepperFlowBloc
    extends Bloc<EnrollmentStepperFlowEvent, EnrollmentStepperFlowState> {
  EnrollmentStepperFlowBloc({
    required int totalSteps,
    required Map<int, StepFormState> initialStepStates,
  }) : super(
         EnrollmentStepperFlowState.initial(
           totalSteps: totalSteps,
           initialStepStates: initialStepStates,
         ),
       ) {
    on<EnrollmentStepperCurrentStepChanged>(_onCurrentStepChanged);
    on<EnrollmentStepperStepStateReported>(_onStepStateReported);
    on<EnrollmentStepperStatesSynced>(_onStatesSynced);
  }

  void _onCurrentStepChanged(
    EnrollmentStepperCurrentStepChanged event,
    Emitter<EnrollmentStepperFlowState> emit,
  ) {
    final boundedStep = event.step.clamp(0, state.totalSteps - 1);
    if (boundedStep == state.currentStep) return;
    emit(state.copyWith(currentStep: boundedStep));
  }

  void _onStepStateReported(
    EnrollmentStepperStepStateReported event,
    Emitter<EnrollmentStepperFlowState> emit,
  ) {
    final current = state.stateOf(event.step);
    if (current == event.stepState) return;
    final nextStates = Map<int, StepFormState>.from(state.stepStates)
      ..[event.step] = event.stepState;
    emit(state.copyWith(stepStates: nextStates));
  }

  void _onStatesSynced(
    EnrollmentStepperStatesSynced event,
    Emitter<EnrollmentStepperFlowState> emit,
  ) {
    emit(
      state.copyWith(stepStates: Map<int, StepFormState>.from(event.states)),
    );
  }
}
