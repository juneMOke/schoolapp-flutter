import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/structure_step.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_error_view.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_step_content.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_step_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockDraftRepository extends Mock
    implements ProvisioningDraftRepository {}

const _catalog = ProvisioningCatalog(
  version: '2026.1',
  country: 'CD',
  cycles: [],
);

void main() {
  late ConfigurationBloc bloc;
  late _MockRepository repository;
  late _MockDraftRepository draftRepository;

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
      () => draftRepository.clear(),
    ).thenAnswer((_) async => const Right(unit));
    bloc = ConfigurationBloc(
      repository: repository,
      draftRepository: draftRepository,
      simulationDebounce: Duration.zero,
    );
  });

  tearDown(() => bloc.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider<ConfigurationBloc>.value(
            value: bloc,
            child: const SingleChildScrollView(
              child: ConfigurationStepContent(),
            ),
          ),
        ),
      ),
    );
    // Pas de `pumpAndSettle` : le pouls des squelettes ne s'arrête jamais.
    await tester.pump();
  }

  void seed({
    required ConfigurationStatus status,
    Failure? failure,
    ConfigurationStep step = ConfigurationStep.structure,
  }) {
    bloc.emit(
      ConfigurationState(
        status: status,
        step: step,
        catalog: _catalog,
        failure: failure,
      ),
    );
  }

  testWidgets('le chargement montre des squelettes, pas l\'étape', (
    tester,
  ) async {
    seed(status: ConfigurationStatus.loading);
    await pump(tester);

    expect(find.byType(ConfigurationStepSkeleton), findsOneWidget);
    expect(find.byType(StructureStep), findsNothing);
  });

  testWidgets('l\'échec remplace le corps de l\'étape', (tester) async {
    // Dans la carte, jamais seulement en toast : un toast disparaît, et l'agent
    // qui revient à l'écran ne saurait plus ce qui a échoué.
    seed(
      status: ConfigurationStatus.failure,
      failure: const NetworkFailure('coupure'),
    );
    await pump(tester);

    expect(find.byType(ConfigurationErrorView), findsOneWidget);
    expect(find.byType(StructureStep), findsNothing);
  });

  testWidgets('le chargement passe AVANT l\'erreur qu\'il rejoue', (
    tester,
  ) async {
    // « Réessayer » repasse en chargement sans que l'échec précédent ait été
    // oublié. Montrer les deux ferait douter de ce qui est en cours.
    bloc.emit(
      const ConfigurationState(
        status: ConfigurationStatus.loading,
        step: ConfigurationStep.structure,
        catalog: _catalog,
        failure: NetworkFailure('coupure'),
      ),
    );
    await pump(tester);

    expect(find.byType(ConfigurationStepSkeleton), findsOneWidget);
    expect(find.byType(ConfigurationErrorView), findsNothing);
  });

  testWidgets('l\'étape revient dès que les données sont là', (tester) async {
    seed(status: ConfigurationStatus.ready);
    await pump(tester);

    expect(find.byType(StructureStep), findsOneWidget);
    expect(find.byType(ConfigurationStepSkeleton), findsNothing);
    expect(find.byType(ConfigurationErrorView), findsNothing);
  });

  testWidgets('un 403 ne propose RIEN à réessayer', (tester) async {
    // Rien de ce que l'utilisateur peut faire ici ne changerait la réponse du
    // serveur : le bouton n'inviterait qu'à recommencer un refus.
    seed(
      status: ConfigurationStatus.failure,
      failure: const UnauthorizedFailure(),
    );
    await pump(tester);

    expect(find.byType(ConfigurationErrorView), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('un 429 non plus', (tester) async {
    seed(
      status: ConfigurationStatus.failure,
      failure: const TooManyRequestsFailure(),
    );
    await pump(tester);

    expect(find.text('Réessayer'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('« année déjà existante » purge le brouillon', (tester) async {
    seed(
      status: ConfigurationStatus.failure,
      failure: const ApiValidationFailure(code: ApiErrorCode.businessRule),
      step: ConfigurationStep.activation,
    );
    await pump(tester);

    await tester.tap(find.text('Revenir à l\'année'));
    // Le bloc naît dans le `setUp`, hors du faux temps du test : le Future que
    // lui rend le dépôt ne se dénoue jamais sous `pump`, et l'état d'après la
    // purge n'arriverait pas. `runAsync` rend la main à l'ordonnanceur réel.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    verify(() => draftRepository.clear()).called(1);
    expect(bloc.state.step, ConfigurationStep.academicYear);
  });

  testWidgets('un 422 recharge les référentiels, jamais le brouillon', (
    tester,
  ) async {
    seed(
      status: ConfigurationStatus.failure,
      failure: const ApiValidationFailure(code: ApiErrorCode.unprocessable),
      step: ConfigurationStep.fees,
    );
    await pump(tester);

    await tester.tap(find.text('Recharger le référentiel'));
    // Même raison qu'au-dessus : sans `runAsync`, le premier appel du handler
    // ne se dénoue pas et le second ne part jamais. Le test passait en isolé
    // et rougissait dans la suite complète — le pire des deux.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    // `forceRefresh` et non un simple rejeu : les deux référentiels sont en
    // cache pour la session, et c'est ce cache-là que le 422 accuse. Le
    // brouillon, lui, n'a rien à voir dans l'affaire — le purger ferait perdre
    // une saisie pour une erreur de référentiel.
    verify(() => repository.loadCatalog(forceRefresh: true)).called(1);
    verify(() => repository.loadFeeCodes(forceRefresh: true)).called(1);
    verifyNever(() => draftRepository.clear());
  });
}
