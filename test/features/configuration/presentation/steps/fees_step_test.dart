import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_draft_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/steps/fees_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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
        CatalogLevel(
          code: 'P6',
          name: '6ème Année Primaire',
          displayOrder: 6,
          defaultSelected: true,
          defaultClassrooms: 1,
          sections: [],
          warnings: [],
        ),
      ],
    ),
  ],
);

/// Le catalogue de frais tel que le serveur le sert : les usuels ET le reste.
const _feeCodes = <FeeCodeOption>[
  FeeCodeOption(code: 'TUITION', label: 'Minerval'),
  FeeCodeOption(code: 'CANTEEN', label: 'Cantine'),
  FeeCodeOption(code: 'LAB_FEE', label: 'Laboratoire'),
  FeeCodeOption(code: 'LIBRARY', label: 'Bibliothèque'),
];

void main() {
  late ConfigurationBloc bloc;
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(const ProvisioningRequest()));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.simulate(any())).thenAnswer(
      (_) async => const Right(
        ProvisioningPlan(
          dryRun: true,
          academicYearId: null,
          academicYearName: '2026-2027',
          counts: ProvisioningCounts(
            cycles: 1,
            levels: 2,
            classrooms: 2,
            courses: 30,
            fees: 2,
          ),
          cycles: [],
          fees: [],
          warnings: [],
        ),
      ),
    );
    bloc = ConfigurationBloc(
      repository: repository,
      draftRepository: _MockDraftRepository(),
      simulationDebounce: Duration.zero,
    );
  });

  tearDown(() => bloc.close());

  void seed({List<FeeInput> fees = const []}) {
    bloc.emit(
      ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.fees,
        catalog: _catalog,
        feeCodes: _feeCodes,
        draft: ProvisioningRequest(
          academicYear: AcademicYearInput(
            name: '2026-2027',
            startDate: DateTime.utc(2026, 9, 1),
            endDate: DateTime.utc(2027, 6, 30),
          ),
          cycles: StructureSelection.defaultFor(_catalog).toCycles(_catalog),
          fees: fees,
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider<ConfigurationBloc>.value(
            value: bloc,
            child: const SingleChildScrollView(child: FeesStep()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FeeInput minerval({FeeScopeInput? scope}) => FeeInput(
    feeCode: 'TUITION',
    label: 'Minerval',
    amountInCents: 68000,
    currency: 'USD',
    dueAt: DateTime.utc(2027, 6, 30, 23, 59, 59),
    appliesTo: scope ?? const FeeScopeInput.allOpenedLevels(),
  );

  testWidgets('sans aucun frais, l\'état vide propose de créer le premier', (
    tester,
  ) async {
    seed();
    await pump(tester);

    expect(find.text('Aucun frais pour l\'instant'), findsOneWidget);
    expect(find.text('Créer le premier frais'), findsOneWidget);
  });

  testWidgets('ouvrir le formulaire fait disparaître l\'état vide', (
    tester,
  ) async {
    seed();
    await pump(tester);

    await tester.tap(find.text('Créer le premier frais'));
    await tester.pumpAndSettle();

    // Deux messages qui disent la même chose se contredisent à l'usage.
    expect(find.text('Aucun frais pour l\'instant'), findsNothing);
    expect(find.text('Nouveau frais'), findsWidgets);
  });

  testWidgets('les types hors des usuels sont atteignables, pas offerts', (
    tester,
  ) async {
    seed();
    await pump(tester);
    await tester.tap(find.text('Créer le premier frais'));
    await tester.pumpAndSettle();

    // Les usuels sont en grille…
    expect(find.widgetWithText(ChoiceChip, 'Minerval'), findsOneWidget);
    // …et les deux autres attendent derrière leur dépliant, sans être perdus.
    expect(find.widgetWithText(ChoiceChip, 'Laboratoire'), findsNothing);
    expect(find.textContaining('Autres types (2)'), findsOneWidget);

    await tester.tap(find.textContaining('Autres types (2)'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, 'Laboratoire'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Bibliothèque'), findsOneWidget);
  });

  testWidgets('choisir un type remplit le libellé et le montant indicatif', (
    tester,
  ) async {
    seed();
    await pump(tester);
    await tester.tap(find.text('Créer le premier frais'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Minerval'));
    await tester.pumpAndSettle();

    // Le montant indicatif du minerval, dans le format d'affichage du projet :
    // un montant entier ne traîne pas ses décimales.
    expect(find.text('680'), findsOneWidget);
    expect(find.text('Minerval'), findsWidgets);
  });

  testWidgets('l\'assiette est une bascule exclusive, jamais deux blocs', (
    tester,
  ) async {
    seed();
    await pump(tester);
    await tester.tap(find.text('Créer le premier frais'));
    await tester.pumpAndSettle();

    // Par défaut : tous les niveaux ouverts, et aucune pilule de niveau.
    expect(find.textContaining('S\'appliquera aux 2 niveaux'), findsOneWidget);
    expect(
      find.widgetWithText(FilterChip, '1ère Année Primaire'),
      findsNothing,
    );

    await tester.tap(find.text('Certains niveaux'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FilterChip, '1ère Année Primaire'),
      findsOneWidget,
    );
    expect(find.textContaining('S\'appliquera aux'), findsNothing);
  });

  testWidgets('une ligne de frais montre son assiette et son échéance', (
    tester,
  ) async {
    seed(fees: [minerval()]);
    await pump(tester);

    expect(find.text('Minerval'), findsOneWidget);
    expect(find.text('TUITION'), findsOneWidget);
    expect(find.textContaining('30/06/2027'), findsOneWidget);
    expect(find.textContaining('Tous les niveaux ouverts'), findsOneWidget);
  });

  testWidgets('les totaux ne mélangent jamais deux devises', (tester) async {
    seed(
      fees: [
        minerval(),
        FeeInput(
          feeCode: 'CANTEEN',
          label: 'Cantine',
          amountInCents: 800000,
          currency: 'CDF',
          dueAt: DateTime.utc(2027, 6, 30, 23, 59, 59),
          appliesTo: const FeeScopeInput.allOpenedLevels(),
        ),
      ],
    );
    await pump(tester);

    // 100 USD et 100 CDF ne font pas 200 de quoi que ce soit.
    final total = find.textContaining('Total catalogue');
    expect(total, findsOneWidget);
    expect(tester.widget<Text>(total).data, contains('USD'));
    expect(tester.widget<Text>(total).data, contains('FC'));
  });

  testWidgets('supprimer un frais est immédiat et le nomme', (tester) async {
    seed(fees: [minerval()]);
    await pump(tester);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Pas de dialogue : la ligne n'est qu'un brouillon local, et le toast la
    // nomme — ce qui suffit à rattraper une erreur de clic.
    expect(bloc.state.draft.fees, isEmpty);
    expect(find.textContaining('« Minerval » supprimé'), findsOneWidget);
  });

  testWidgets('les actions de ligne se ferment quand un formulaire est ouvert', (
    tester,
  ) async {
    seed(fees: [minerval()]);
    await pump(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    // Deux appels à l'action concurrents feraient hésiter sur celui qui compte.
    expect(find.widgetWithText(FilledButton, 'Nouveau frais'), findsNothing);
    expect(find.text('Modifier le frais'), findsOneWidget);
  });
}
