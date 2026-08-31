import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stepper_flow_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_state_helper.dart';

/// Le pied du stepper lit l'état de l'étape **courante**, et cet état a deux
/// sources : ce que l'étape montée rapporte, et ce que le dossier sème à
/// chaque rechargement — il y en a un après chaque enregistrement.
///
/// Ces deux sources ne se valent pas. L'étape courante est la seule montée :
/// elle voit le formulaire tel qu'il est à l'écran. Le semis, lui, ne lit que
/// le dossier persisté, et pour l'étape Frais il ne lit rien du tout — il se
/// pose invalide en dur, la grille tarifaire n'étant pas dans le dossier.
/// Laisser le semis écraser l'étape courante refermait la porte à l'instant
/// même de l'enregistrement.
void main() {
  EnrollmentStepperFlowBloc buildBloc({
    required Map<int, StepFormState> semis,
  }) => EnrollmentStepperFlowBloc(totalSteps: 7, initialStepStates: semis);

  /// Ce que sème `StudentChargesStepHandler` : invalide, en dur.
  const semisFrais = <int, StepFormState>{
    4: StepFormState(dirty: false, valid: false, saving: false),
  };

  group('rechargement du dossier', () {
    test(
      'l\'étape courante garde ce qu\'elle a rapporté, le semis ne l\'écrase pas',
      () async {
        final bloc = buildBloc(semis: semisFrais);
        addTearDown(bloc.close);

        bloc.add(const EnrollmentStepperCurrentStepChanged(4));
        await Future<void>.delayed(Duration.zero);

        // L'étape montée se signale : grille chargée, rien à enregistrer.
        bloc.add(
          const EnrollmentStepperStepStateReported(
            step: 4,
            stepState: StepFormState(dirty: false, valid: true, saving: false),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.canContinue, isTrue);

        // Enregistrement → rechargement du dossier → le semis repart.
        bloc.add(const EnrollmentStepperStatesSynced(semisFrais));
        await Future<void>.delayed(Duration.zero);

        expect(
          bloc.state.canContinue,
          isTrue,
          reason: 'le dossier ne sait pas ce que l\'étape montée sait',
        );
      },
    );

    test('les étapes NON montées, elles, prennent bien le semis', () async {
      final bloc = buildBloc(
        semis: const {
          0: StepFormState(dirty: false, valid: false, saving: false),
        },
      );
      addTearDown(bloc.close);

      bloc.add(
        const EnrollmentStepperStatesSynced(<int, StepFormState>{
          0: StepFormState(dirty: false, valid: false, saving: false),
          3: StepFormState(dirty: false, valid: true, saving: false),
        }),
      );
      await Future<void>.delayed(Duration.zero);

      // L'étape 3 n'est pas montée : le dossier en est la seule source.
      expect(bloc.state.stateOf(3).valid, isTrue);
    });

    /// La garde ne doit pas non plus figer une étape courante : ce qu'elle
    /// rapporte APRÈS le semis fait toujours foi.
    test('ce que l\'étape rapporte après le semis fait foi', () async {
      final bloc = buildBloc(semis: semisFrais);
      addTearDown(bloc.close);

      bloc.add(const EnrollmentStepperCurrentStepChanged(4));
      bloc.add(
        const EnrollmentStepperStepStateReported(
          step: 4,
          stepState: StepFormState(dirty: false, valid: true, saving: false),
        ),
      );
      bloc.add(const EnrollmentStepperStatesSynced(semisFrais));
      bloc.add(
        const EnrollmentStepperStepStateReported(
          step: 4,
          stepState: StepFormState(dirty: true, valid: true, saving: false),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // Modifiée et non enregistrée : la porte se referme, et c'est correct.
      expect(bloc.state.canContinue, isFalse);
      expect(bloc.state.canSave, isTrue);
    });
  });
}
