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

  /// Le dossier re-sème l'état de TOUTES les étapes à chaque rechargement — il
  /// y en a un après chaque enregistrement, et `EnrollmentDetail` n'ayant pas
  /// d'égalité de valeur, la moindre nouvelle instance suffit à le déclencher.
  ///
  /// L'étape COURANTE est la seule montée : elle seule connaît le formulaire
  /// tel qu'il est à l'écran, et son état est le seul que le pied du stepper
  /// lise. Lui réappliquer le semis, c'était remplacer ce qu'elle rapporte par
  /// ce que le dossier laisse deviner — or le semis ne devine pas toujours :
  /// l'étape Frais, elle, se sème invalide **en dur**, faute de pouvoir
  /// consulter la grille depuis le dossier.
  ///
  /// La porte se refermait donc derrière l'usager à l'instant même où il
  /// venait d'enregistrer : « Continuer » éteint, et « Enregistrer » avec lui
  /// puisque plus rien n'était modifié. Seul un aller-retour vers une autre
  /// étape — qui remonte le widget et le fait se re-signaler — en sortait.
  ///
  /// Le semis garde donc les étapes non montées, dont il est la seule source ;
  /// l'étape courante garde ce qu'elle a rapporté. Si le rechargement la
  /// concerne vraiment, elle se ré-hydrate et se re-signale d'elle-même.
  void _onStatesSynced(
    EnrollmentStepperStatesSynced event,
    Emitter<EnrollmentStepperFlowState> emit,
  ) {
    final nextStates = Map<int, StepFormState>.from(event.states);
    final reportedByCurrentStep = state.stepStates[state.currentStep];
    if (reportedByCurrentStep != null) {
      nextStates[state.currentStep] = reportedByCurrentStep;
    }
    emit(state.copyWith(stepStates: nextStates));
  }
}
