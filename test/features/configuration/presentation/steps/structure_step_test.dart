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
import 'package:school_app_flutter/features/configuration/presentation/steps/structure_step.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

class _MockDraftRepository extends Mock
    implements ProvisioningDraftRepository {}

const _catalog = ProvisioningCatalog(
  version: '2026.1',
  country: 'CD',
  cycles: [
    CatalogCycle(
      code: 'MAT',
      name: 'Cycle Maternel',
      periodType: 'TRIMESTER',
      displayOrder: 1,
      defaultSelected: true,
      levels: [
        CatalogLevel(
          code: 'M1',
          name: '1ère Maternelle',
          displayOrder: 1,
          defaultSelected: true,
          defaultClassrooms: 1,
          sections: [],
          warnings: ['NO_OFFICIAL_GRID'],
        ),
      ],
    ),
    CatalogCycle(
      code: 'HG',
      name: 'Humanités Générales',
      periodType: 'SEMESTER',
      displayOrder: 4,
      defaultSelected: true,
      levels: [
        CatalogLevel(
          code: 'HG1',
          name: '1ère Année Humanités',
          displayOrder: 1,
          defaultSelected: true,
          defaultClassrooms: 1,
          sections: [
            CatalogSection(
              officialCode: 'SCI_1',
              filiere: 'SCIENTIFIQUE',
              filiereAbregee: 'Sci',
              libelle: 'Humanités Scientifiques',
              codeOfficiel: 'IGE/P.S/012',
              courseCount: 24,
            ),
            CatalogSection(
              officialCode: 'PED_1',
              filiere: 'PEDAGOGIE',
              filiereAbregee: 'Péd',
              libelle: 'Pédagogie générale',
              codeOfficiel: 'IGE/P.S/018',
              courseCount: 21,
            ),
          ],
          warnings: [],
        ),
      ],
    ),
  ],
);

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
            cycles: 2,
            levels: 2,
            classrooms: 3,
            courses: 45,
            fees: 0,
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

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: BlocProvider<ConfigurationBloc>.value(
            value: bloc,
            child: const SingleChildScrollView(child: StructureStep()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void seed(StructureSelection selection, {ProvisioningPlan? plan}) {
    bloc.emit(
      ConfigurationState(
        status: ConfigurationStatus.ready,
        step: ConfigurationStep.structure,
        catalog: _catalog,
        feeCodes: const <FeeCodeOption>[],
        draft: ProvisioningRequest(cycles: selection.toCycles(_catalog)),
        plan: plan,
      ),
    );
  }

  testWidgets('un niveau à barèmes montre une ligne PAR filière', (
    tester,
  ) async {
    seed(StructureSelection.defaultFor(_catalog));
    await pump(tester);

    // Et non un compteur unique : le serveur refuse qu'on lui dise « deux
    // classes » sans dire lesquelles.
    expect(find.text('Humanités Scientifiques'), findsOneWidget);
    expect(find.text('Pédagogie générale'), findsOneWidget);
  });

  testWidgets('chaque barème annonce ce qu\'il coûte en cours', (tester) async {
    seed(StructureSelection.defaultFor(_catalog));
    await pump(tester);

    // C'est ce que coûtera une classe de cette filière — un chiffre que la
    // révision 1 de la spécification ne pouvait pas connaître.
    expect(find.textContaining('24 cours'), findsOneWidget);
    expect(find.textContaining('21 cours'), findsOneWidget);
  });

  testWidgets('un niveau sans barème le dit sans bloquer', (tester) async {
    seed(StructureSelection.defaultFor(_catalog));
    await pump(tester);

    expect(
      find.textContaining('Aucun barème officiel'),
      findsOneWidget,
      reason: 'lu dans warnings, jamais déduit d\'une liste de sections vide',
    );
  });

  testWidgets('les totaux affichés viennent du plan, pas des cases', (
    tester,
  ) async {
    // La sélection par défaut ouvre 3 classes ; le serveur en annonce 3 aussi,
    // mais le test le prouve en faisant mentir le plan.
    seed(
      StructureSelection.defaultFor(_catalog),
      plan: const ProvisioningPlan(
        dryRun: true,
        academicYearId: null,
        academicYearName: '2026-2027',
        counts: ProvisioningCounts(
          cycles: 2,
          levels: 2,
          classrooms: 42,
          courses: 999,
          fees: 0,
        ),
        cycles: [],
        fees: [],
        warnings: [],
      ),
    );
    await pump(tester);

    expect(find.text('42'), findsOneWidget);
    expect(find.text('999'), findsOneWidget);
  });

  testWidgets('sans aucun niveau retenu, l\'état vide propose une issue', (
    tester,
  ) async {
    seed(StructureSelection.empty);
    await pump(tester);

    expect(find.text('Aucun niveau retenu'), findsOneWidget);
    expect(find.text('Rétablir la proposition'), findsOneWidget);
  });

  testWidgets('rétablir reconstruit la proposition depuis le catalogue', (
    tester,
  ) async {
    seed(StructureSelection.empty);
    await pump(tester);

    await tester.tap(find.text('Rétablir la proposition'));
    await tester.pumpAndSettle();

    // 1 maternelle + 2 filières d'humanités.
    final selection = StructureSelection.fromDraft(bloc.state.draft, _catalog);
    expect(selection.counts.length, 3);
    expect(selection.countFor('HG1|SCI_1'), 1);
  });

  testWidgets('le bandeau de totaux disparaît pendant une erreur', (
    tester,
  ) async {
    bloc.emit(
      ConfigurationState(
        status: ConfigurationStatus.failure,
        step: ConfigurationStep.structure,
        catalog: _catalog,
        draft: ProvisioningRequest(
          cycles: StructureSelection.defaultFor(_catalog).toCycles(_catalog),
        ),
      ),
    );
    await pump(tester);

    // Mieux vaut aucun chiffre qu'un chiffre faux.
    expect(find.text('Cycle Maternel'), findsOneWidget);
    expect(find.byIcon(Icons.donut_large_rounded), findsNothing);
  });
}
