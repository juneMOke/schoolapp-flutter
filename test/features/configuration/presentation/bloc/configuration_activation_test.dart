import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockDraftRepository extends Mock
    implements ProvisioningDraftRepository {}

final _draft = ProvisioningRequest(
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
);

const _activated = ProvisioningPlan(
  dryRun: false,
  academicYearId: 'uuid-annee',
  academicYearName: '2026-2027',
  counts: ProvisioningCounts(
    cycles: 1,
    levels: 1,
    classrooms: 2,
    courses: 34,
    fees: 2,
  ),
  cycles: [],
  fees: [],
  warnings: [],
);

void main() {
  late _MockRepository repository;
  late _MockDraftRepository draftRepository;

  setUpAll(() => registerFallbackValue(const ProvisioningRequest()));

  setUp(() {
    repository = _MockRepository();
    draftRepository = _MockDraftRepository();
    when(
      () => repository.activate(any()),
    ).thenAnswer((_) async => const Right(_activated));
    when(
      () => draftRepository.clear(),
    ).thenAnswer((_) async => const Right(unit));
  });

  ConfigurationBloc build() => ConfigurationBloc(
    repository: repository,
    draftRepository: draftRepository,
    simulationDebounce: Duration.zero,
  );

  ConfigurationState seed({bool activating = false}) => ConfigurationState(
    status: ConfigurationStatus.ready,
    step: ConfigurationStep.activation,
    draft: _draft,
    isActivating: activating,
  );

  group('activation', () {
    blocTest<ConfigurationBloc, ConfigurationState>(
      'le succès met l\'école en service et détruit le brouillon',
      build: build,
      seed: seed,
      act: (bloc) => bloc.add(const ConfigurationActivationRequested()),
      verify: (bloc) {
        expect(bloc.state.isActivated, isTrue);
        expect(bloc.state.activatedPlan?.academicYearId, 'uuid-annee');
        // Un brouillon qui survivrait à une activation réussie rejouerait
        // l'assistant jusqu'au refus « année déjà existante », que rien à
        // l'écran ne saurait expliquer.
        verify(() => draftRepository.clear()).called(1);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'l\'échec ne détruit RIEN, ni côté client ni à l\'écran',
      build: () {
        when(
          () => repository.activate(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('panne')));
        return build();
      },
      seed: seed,
      act: (bloc) => bloc.add(const ConfigurationActivationRequested()),
      verify: (bloc) {
        expect(bloc.state.isActivated, isFalse);
        expect(bloc.state.failure, isA<ServerFailure>());
        // La transaction est annulée côté serveur, et le brouillon reste
        // intact côté client : rien n'est perdu.
        expect(bloc.state.draft, _draft);
        verifyNever(() => draftRepository.clear());
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un second appel pendant l\'activation est ignoré',
      build: build,
      seed: () => seed(activating: true),
      act: (bloc) => bloc.add(const ConfigurationActivationRequested()),
      verify: (_) {
        // Ce geste n'est pas idempotent : un second appel se ferait refuser en
        // « année déjà existante », et l'écran ne saurait pas dire si le
        // premier a abouti.
        verifyNever(() => repository.activate(any()));
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'réactiver une école déjà en service est ignoré',
      build: build,
      seed: () => ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.activation,
        draft: _draft,
        activatedPlan: _activated,
      ),
      act: (bloc) => bloc.add(const ConfigurationActivationRequested()),
      verify: (_) => verifyNever(() => repository.activate(any())),
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un délai de réception ne se rejoue pas tout seul',
      build: () {
        when(() => repository.activate(any())).thenAnswer(
          // La requête est partie, son sort est inconnu : le serveur peut
          // l'avoir exécutée intégralement.
          (_) async => const Left(UncertainOutcomeFailure()),
        );
        return build();
      },
      seed: seed,
      act: (bloc) => bloc.add(const ConfigurationActivationRequested()),
      verify: (bloc) {
        expect(bloc.state.failure, isA<UncertainOutcomeFailure>());
        // Et surtout : le brouillon reste, parce qu'on ne sait pas.
        verifyNever(() => draftRepository.clear());
      },
    );
  });

  group('contrôles d\'activation', () {
    test('ils portent sur le plan, pas sur les cases cochées', () {
      // Le brouillon ouvre 2 classes ; sans plan, le contrôle ne passe pas —
      // c'est le serveur qui dit ce qui sera écrit.
      final state = seed();
      expect(state.hasClassrooms, isFalse);

      final withPlan = state.copyWith(plan: _activated);
      expect(withPlan.hasClassrooms, isTrue);
    });

    test('une année sans intervalle valide ne passe pas', () {
      final state = ConfigurationState(
        draft: ProvisioningRequest(
          academicYear: AcademicYearInput(
            name: '2026-2027',
            startDate: DateTime.utc(2027, 6, 30),
            endDate: DateTime.utc(2026, 9, 1),
          ),
        ),
      );
      expect(state.hasDatedYear, isFalse);
    });

    test('sans frais, le contrôle ne passe pas', () {
      expect(seed().hasFees, isFalse);
    });
  });
}
