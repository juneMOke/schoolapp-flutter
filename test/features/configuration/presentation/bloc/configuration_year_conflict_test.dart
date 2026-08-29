import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockDraftRepository extends Mock
    implements ProvisioningDraftRepository {}

void main() {
  late _MockDraftRepository draftRepository;

  setUp(() {
    draftRepository = _MockDraftRepository();
    when(
      () => draftRepository.clear(),
    ).thenAnswer((_) async => const Right(unit));
  });

  blocTest<ConfigurationBloc, ConfigurationState>(
    'le refus « année déjà existante » purge le brouillon et remonte à l\'année',
    build: () => ConfigurationBloc(
      repository: _MockRepository(),
      draftRepository: draftRepository,
    ),
    seed: () => ConfigurationState(
      status: ConfigurationStatus.failure,
      step: ConfigurationStep.activation,
      maxStep: 4,
      doneSteps: const {0, 1, 2, 3},
      draft: ProvisioningRequest(
        academicYear: AcademicYearInput(
          name: '2026-2027',
          startDate: DateTime.utc(2026, 9, 1),
          endDate: DateTime.utc(2027, 6, 30),
        ),
        cycles: const [
          CycleInput(
            catalogCode: 'PRIM',
            levels: [LevelInput(catalogCode: 'P1', classrooms: 2)],
          ),
        ],
      ),
    ),
    act: (bloc) => bloc.add(const ConfigurationYearConflictAcknowledged()),
    verify: (bloc) {
      // Garder le brouillon ferait rejouer exactement la même année à chaque
      // tentative, sans que rien à l'écran ne l'explique.
      verify(() => draftRepository.clear()).called(1);
      expect(bloc.state.draft, ProvisioningRequest.empty);
      expect(bloc.state.step, ConfigurationStep.academicYear);
      expect(bloc.state.status, ConfigurationStatus.ready);
      expect(bloc.state.failure, isNull);
      // La structure et les frais s'en vont avec : ils appartenaient à cette
      // année-là, et les rattacher à une autre serait une décision que personne
      // n'a prise.
      expect(bloc.state.draft.cycles, isEmpty);
      expect(bloc.state.doneSteps, isEmpty);
    },
  );

  blocTest<ConfigurationBloc, ConfigurationState>(
    'le rang atteint survit — l\'agent ne repart pas de zéro',
    build: () => ConfigurationBloc(
      repository: _MockRepository(),
      draftRepository: draftRepository,
    ),
    seed: () => const ConfigurationState(
      status: ConfigurationStatus.failure,
      step: ConfigurationStep.activation,
      maxStep: 4,
    ),
    act: (bloc) => bloc.add(const ConfigurationYearConflictAcknowledged()),
    verify: (bloc) => expect(bloc.state.maxStep, 4),
  );
}
