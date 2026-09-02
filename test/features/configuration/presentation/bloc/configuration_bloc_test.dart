import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/data/local/provisioning_draft_dao.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockDraftRepository extends Mock
    implements ProvisioningDraftRepository {}

const _catalog = ProvisioningCatalog(
  version: '2026.1',
  country: 'CD',
  cycles: [
    CatalogCycle(
      code: 'PRIM',
      name: 'Cycle Primaire',
      periodType: 'TRIMESTER',
      displayOrder: 2,
      defaultSelected: true,
      levels: [
        CatalogLevel(
          code: 'P1',
          name: '1ère Année Primaire',
          displayOrder: 1,
          defaultSelected: true,
          defaultClassrooms: 1,
          sections: [],
          warnings: [],
        ),
      ],
    ),
  ],
);

ProvisioningPlan _plan({int classrooms = 6}) => ProvisioningPlan(
  dryRun: true,
  academicYearId: null,
  academicYearName: '2026-2027',
  counts: ProvisioningCounts(
    cycles: 1,
    levels: 1,
    classrooms: classrooms,
    courses: 17,
    fees: 0,
  ),
  cycles: const [],
  fees: const [],
  warnings: const [],
);

ProvisioningRequest _simulatableDraft({int classrooms = 1}) =>
    ProvisioningRequest(
      academicYear: AcademicYearInput(
        name: '2026-2027',
        startDate: DateTime.utc(2026, 9, 1),
        endDate: DateTime.utc(2027, 6, 30),
      ),
      cycles: [
        CycleInput(
          catalogCode: 'PRIM',
          levels: [LevelInput(catalogCode: 'P1', classrooms: classrooms)],
        ),
      ],
    );

void main() {
  late _MockRepository repository;
  late _MockDraftRepository draftRepository;

  setUpAll(() {
    registerFallbackValue(const ProvisioningRequest());
  });

  setUp(() {
    repository = _MockRepository();
    draftRepository = _MockDraftRepository();

    when(
      () => repository.loadCatalog(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const Right(_catalog));
    when(
      () => repository.loadFeeCodes(
        forceRefresh: any(named: 'forceRefresh'),
        includeHidden: any(named: 'includeHidden'),
      ),
    ).thenAnswer((_) async => const Right(<FeeCodeOption>[]));
    when(
      () => repository.simulate(any()),
    ).thenAnswer((_) async => Right(_plan()));
    when(() => draftRepository.load()).thenAnswer((_) async => null);
    when(
      () => draftRepository.save(
        request: any(named: 'request'),
        step: any(named: 'step'),
        maxStep: any(named: 'maxStep'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  ConfigurationBloc build() => ConfigurationBloc(
    repository: repository,
    draftRepository: draftRepository,
    // Débit immédiat : la temporisation est une propriété de confort, pas une
    // règle métier, et l'attendre en test ne prouverait rien de plus.
    simulationDebounce: Duration.zero,
  );

  group('ouverture', () {
    blocTest<ConfigurationBloc, ConfigurationState>(
      'charge les deux catalogues à l\'entrée, pas à l\'entrée de leur étape',
      build: build,
      act: (bloc) => bloc.add(const ConfigurationStarted()),
      verify: (_) {
        // Le promoteur passe une à deux minutes sur les étapes 1 et 2 : le
        // catalogue est là quand il arrive au cœur, et le point de fragilité
        // réseau se déplace là où rien n'est encore investi.
        verify(() => repository.loadCatalog()).called(1);
        verify(() => repository.loadFeeCodes()).called(1);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un catalogue de frais indisponible ne ferme pas l\'assistant',
      build: () {
        when(
          () => repository.loadFeeCodes(
            forceRefresh: any(named: 'forceRefresh'),
            includeHidden: any(named: 'includeHidden'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));
        return build();
      },
      act: (bloc) => bloc.add(const ConfigurationStarted()),
      verify: (bloc) {
        // Seule l'étape 4 en a besoin : échouer à l'entrée fermerait tout le
        // parcours pour une route qui ne sert qu'au bout.
        expect(bloc.state.status, ConfigurationStatus.ready);
        expect(bloc.state.catalog, isNotNull);
        expect(bloc.state.feeCodes, isEmpty);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un catalogue pédagogique indisponible, lui, arrête tout',
      build: () {
        when(
          () =>
              repository.loadCatalog(forceRefresh: any(named: 'forceRefresh')),
        ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));
        return build();
      },
      act: (bloc) => bloc.add(const ConfigurationStarted()),
      verify: (bloc) {
        expect(bloc.state.status, ConfigurationStatus.failure);
        expect(bloc.state.failure, isA<NetworkFailure>());
      },
    );
  });

  group('reprise du brouillon', () {
    blocTest<ConfigurationBloc, ConfigurationState>(
      'rouvre sur l\'étape où la saisie s\'était arrêtée',
      build: () {
        when(() => draftRepository.load()).thenAnswer(
          (_) async => ProvisioningDraft(
            request: _simulatableDraft(),
            step: 2,
            maxStep: 3,
            updatedAt: DateTime.utc(2026, 8, 28),
          ),
        );
        return build();
      },
      act: (bloc) => bloc.add(const ConfigurationStarted()),
      verify: (bloc) {
        expect(bloc.state.step, ConfigurationStep.structure);
        expect(bloc.state.maxStep, 3);
        expect(bloc.state.draft.cycles, hasLength(1));
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un rang hors bornes ne fait pas exploser l\'ouverture',
      build: () {
        when(() => draftRepository.load()).thenAnswer(
          (_) async => ProvisioningDraft(
            // Brouillon écrit par une version future, ou simplement abîmé.
            request: _simulatableDraft(),
            step: 42,
            maxStep: 42,
            updatedAt: DateTime.utc(2026, 8, 28),
          ),
        );
        return build();
      },
      act: (bloc) => bloc.add(const ConfigurationStarted()),
      verify: (bloc) {
        // Lever ici laisserait l'agent devant un écran mort, sa saisie intacte
        // et inaccessible.
        expect(bloc.state.step, ConfigurationStep.activation);
        expect(bloc.state.status, isNot(ConfigurationStatus.initial));
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un brouillon simulable relance la simulation à l\'ouverture',
      build: () {
        when(() => draftRepository.load()).thenAnswer(
          (_) async => ProvisioningDraft(
            request: _simulatableDraft(),
            step: 2,
            maxStep: 2,
            updatedAt: DateTime.utc(2026, 8, 28),
          ),
        );
        return build();
      },
      act: (bloc) => bloc.add(const ConfigurationStarted()),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        // Sans cela, l'étape 3 rouvrirait avec des totaux à zéro sur un
        // brouillon plein — et annoncerait « 0 classe seront créées ».
        expect(bloc.state.plan, isNotNull);
        expect(bloc.state.counts.classrooms, 6);
      },
    );
  });

  group('simulation', () {
    blocTest<ConfigurationBloc, ConfigurationState>(
      'les totaux viennent du plan, jamais du brouillon',
      build: build,
      seed: () => const ConfigurationState(status: ConfigurationStatus.ready),
      act: (bloc) async {
        bloc.add(ConfigurationDraftChanged(_simulatableDraft(classrooms: 2)));
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        // Le brouillon dit 2 classes, le serveur en annonce 6 : c'est le
        // serveur qui a raison, et c'est lui qu'on affiche. Un total local qui
        // diverge du plan est un engagement chiffré faux juste avant une
        // écriture irréversible.
        expect(bloc.state.counts.classrooms, 6);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un brouillon sans année n\'est jamais simulé',
      build: build,
      seed: () => const ConfigurationState(status: ConfigurationStatus.ready),
      act: (bloc) => bloc.add(
        const ConfigurationDraftChanged(
          ProvisioningRequest(
            cycles: [
              CycleInput(
                catalogCode: 'PRIM',
                levels: [LevelInput(catalogCode: 'P1', classrooms: 1)],
              ),
            ],
          ),
        ),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        // La simulation valide l'année en premier : partir quand même ne
        // rapporterait qu'un 400 et une fausse alerte au journal du serveur.
        verifyNever(() => repository.simulate(any()));
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'une modification sans effet sur le plan ne simule pas',
      build: build,
      seed: () => const ConfigurationState(status: ConfigurationStatus.ready),
      act: (bloc) => bloc.add(
        ConfigurationDraftChanged(_simulatableDraft(), simulate: false),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (_) => verifyNever(() => repository.simulate(any())),
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'une simulation périmée n\'écrase pas la plus récente',
      build: () {
        var call = 0;
        when(() => repository.simulate(any())).thenAnswer((_) async {
          call++;
          // La première réponse arrive APRÈS la seconde : c'est exactement la
          // course que le compteur de génération existe pour perdre.
          if (call == 1) {
            await Future<void>.delayed(const Duration(milliseconds: 60));
            return Right(_plan(classrooms: 999));
          }
          return Right(_plan(classrooms: 6));
        });
        return build();
      },
      seed: () => const ConfigurationState(status: ConfigurationStatus.ready),
      act: (bloc) async {
        bloc.add(ConfigurationDraftChanged(_simulatableDraft(classrooms: 1)));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(ConfigurationDraftChanged(_simulatableDraft(classrooms: 2)));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        // 999 est la réponse de la requête abandonnée : l'afficher montrerait
        // des totaux ne correspondant à rien de ce qui est coché à l'écran.
        expect(bloc.state.counts.classrooms, 6);
        expect(bloc.state.isSimulating, isFalse);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un échec de simulation efface le plan précédent',
      build: () {
        when(
          () => repository.simulate(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));
        return build();
      },
      seed: () => ConfigurationState(
        status: ConfigurationStatus.ready,
        plan: _plan(classrooms: 42),
      ),
      act: (bloc) => bloc.add(ConfigurationDraftChanged(_simulatableDraft())),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        // Garder les totaux d'avant l'échec les ferait passer pour ceux du
        // brouillon courant — un chiffre faux et rassurant.
        expect(bloc.state.plan, isNull);
        expect(bloc.state.counts.classrooms, 0);
        expect(bloc.state.status, ConfigurationStatus.failure);
      },
    );
  });

  group('progression', () {
    blocTest<ConfigurationBloc, ConfigurationState>(
      'continuer enregistre le brouillon et avance',
      build: build,
      seed: () => const ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.academicYear,
        maxStep: 1,
      ),
      act: (bloc) => bloc.add(const ConfigurationContinueRequested()),
      verify: (bloc) {
        expect(bloc.state.step, ConfigurationStep.structure);
        expect(bloc.state.maxStep, 2);
        expect(bloc.state.doneSteps, contains(1));
        verify(
          () => draftRepository.save(
            request: any(named: 'request'),
            step: 2,
            maxStep: any(named: 'maxStep'),
          ),
        ).called(1);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'revenir en arrière ne fait pas reculer le rang atteint',
      build: build,
      seed: () => const ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.fees,
        maxStep: 3,
      ),
      act: (bloc) => bloc.add(const ConfigurationBackRequested()),
      verify: (bloc) {
        // Sinon l'agent qui recule pour corriger une date perdrait l'accès aux
        // étapes qu'il venait de remplir.
        expect(bloc.state.step, ConfigurationStep.structure);
        expect(bloc.state.maxStep, 3);
        expect(bloc.state.progression.statusAt(3).canTap, isTrue);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un saut vers une étape jamais atteinte est ignoré',
      build: build,
      seed: () => const ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.school,
        maxStep: 0,
      ),
      act: (bloc) => bloc.add(
        const ConfigurationStepSelected(ConfigurationStep.activation),
      ),
      verify: (bloc) => expect(bloc.state.step, ConfigurationStep.school),
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'la coche d\'enregistrement ne survit pas au changement d\'étape',
      build: build,
      seed: () => const ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.academicYear,
        maxStep: 3,
        justSaved: true,
      ),
      act: (bloc) =>
          bloc.add(const ConfigurationStepSelected(ConfigurationStep.fees)),
      verify: (bloc) {
        // Elle atteste d'un enregistrement, pas d'un état durable.
        expect(bloc.state.justSaved, isFalse);
      },
    );

    blocTest<ConfigurationBloc, ConfigurationState>(
      'un brouillon non enregistré se dit',
      build: () {
        when(
          () => draftRepository.save(
            request: any(named: 'request'),
            step: any(named: 'step'),
            maxStep: any(named: 'maxStep'),
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('disque plein')));
        return build();
      },
      seed: () => const ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.academicYear,
      ),
      act: (bloc) => bloc.add(const ConfigurationSaveRequested()),
      verify: (bloc) {
        // L'agent doit savoir que sa saisie ne survivra pas à la fermeture de
        // l'application. Une lecture se tait, une écriture se dit.
        expect(bloc.state.failure, isA<StorageFailure>());
        expect(bloc.state.justSaved, isFalse);
      },
    );
  });
}
