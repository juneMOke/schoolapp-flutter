import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/find_boutique_payer_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/record_boutique_sale_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_article_card.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetCatalog extends Mock implements GetBoutiqueCatalogUseCase {}

class _MockFindPayer extends Mock implements FindBoutiquePayerUseCase {}

class _MockRecordSale extends Mock implements RecordBoutiqueSaleUseCase {}

class _MockAcademicYearBloc
    extends MockBloc<AcademicYearContextEvent, AcademicYearContextState>
    implements AcademicYearContextBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Un bloc dont l'état de départ est imposé — pour observer l'écran d'après
/// l'encaissement sans rejouer tout le parcours.
class _SeededBloc extends BoutiqueBloc {
  _SeededBloc({
    required super.getCatalog,
    required super.findPayer,
    required super.recordSale,
    required super.ids,
    required BoutiqueState seed,
  }) {
    emit(seed);
  }
}

class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'k${_n++}';
}

const _polo = BoutiqueArticle(
  id: 'art-polo',
  academicYearId: 'ay-1',
  code: 'POLO',
  label: 'Polo Lacoste',
  family: ArticleFamily.uniforme,
  pricingMode: PricingMode.prixParNiveau,
  levelPrices: {'lvl-1': 1000},
  currency: 'USD',
);

/// Contexte académique complet — c'est **exactement** cette forme que la page
/// aplatit pour son sélecteur de niveau, et un accès fautif y planterait.
AcademicYearContextState _readyContext() => const AcademicYearContextState(
  status: AcademicYearContextLoadStatus.success,
  context: AcademicYearContext(
    academicYear: AcademicYear(id: 'ay-1', name: '2026-2027', current: true),
    schoolLevelGroups: [
      SchoolLevelGroupBundle(
        group: SchoolLevelGroup(
          id: 'grp-1',
          name: 'Primaire',
          code: 'PRIM',
          displayOrder: 1,
        ),
        levels: [
          SchoolLevel(
            id: 'lvl-1',
            name: '1ère primaire',
            code: 'P1',
            displayOrder: 1,
            splitIntoClassrooms: false,
          ),
        ],
      ),
    ],
  ),
);

void main() {
  late _MockGetCatalog getCatalog;
  late _MockFindPayer findPayer;
  late _MockRecordSale recordSale;
  late _MockAcademicYearBloc academicYearBloc;
  late _MockAuthBloc authBloc;

  setUp(() {
    getCatalog = _MockGetCatalog();
    findPayer = _MockFindPayer();
    recordSale = _MockRecordSale();
    when(() => findPayer(any())).thenAnswer((_) async => null);
    academicYearBloc = _MockAcademicYearBloc();
    authBloc = _MockAuthBloc();

    when(() => getCatalog(any())).thenAnswer(
      (_) async =>
          const Right(BoutiqueCatalog(articles: [_polo], withheld: false)),
    );
    when(() => academicYearBloc.state).thenReturn(_readyContext());
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.authenticated));

    GetIt.I.registerFactory<BoutiqueBloc>(
      () => BoutiqueBloc(
        getCatalog: getCatalog,
        findPayer: findPayer,
        recordSale: recordSale,
        ids: _SeqIds(),
      ),
    );
  });

  tearDown(() => GetIt.I.reset());

  Future<void> pumpPage(WidgetTester tester, {BoutiqueState? seed}) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    if (seed != null) {
      GetIt.I.unregister<BoutiqueBloc>();
      GetIt.I.registerFactory<BoutiqueBloc>(
        () => _SeededBloc(
          getCatalog: getCatalog,
          findPayer: findPayer,
          recordSale: recordSale,
          ids: _SeqIds(),
          seed: seed,
        ),
      );
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AcademicYearContextBloc>.value(value: academicYearBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          // Pas de scroll enveloppant : `AppPageBackground` porte déjà le
          // sien, et deux couches donnent une hauteur non bornée.
          home: BoutiquePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la page se monte et rend le catalogue', (tester) async {
    // Ce test existe pour une raison précise : le sélecteur de niveau aplatit
    // `schoolLevelGroups`, dont le type se laisse inférer en `dynamic` sur une
    // liste vide littérale. L'analyse laisse alors passer un accès à un membre
    // qui n'existe pas, et l'erreur n'apparaît que sous le doigt du guichet.
    await pumpPage(tester);

    expect(find.text('Polo Lacoste'), findsOneWidget);
    expect(find.byType(BoutiqueArticleCard), findsOneWidget);
  });

  testWidgets('taper une carte pose une ligne au panier', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(BoutiqueArticleCard));
    await tester.pumpAndSettle();

    // La ligne est là, avec sa mention « Prix à résoudre » : l'article est
    // tarifé par niveau, et aucun n'a été choisi.
    expect(find.text('Prix à résoudre'), findsOneWidget);
    // Et jamais un « 0.00 $ » qui ferait croire la ligne gratuite.
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('le bouton d\'encaissement NOMME ce qui manque', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byType(BoutiqueArticleCard));
    await tester.pumpAndSettle();

    // Jamais grisé muet : le pied énumère, dans l'ordre où le guichet peut
    // corriger.
    expect(find.textContaining('À compléter :'), findsOneWidget);
    expect(find.textContaining('1 ligne sans niveau'), findsOneWidget);
  });

  testWidgets('catalogue retenu : « non communiqué », jamais « vide »', (
    tester,
  ) async {
    when(
      () => getCatalog(any()),
    ).thenAnswer((_) async => const Right(BoutiqueCatalog.withheld()));

    await pumpPage(tester);

    expect(find.text('Catalogue non communiqué'), findsOneWidget);
    expect(find.text('Aucun article au catalogue'), findsNothing);
  });

  testWidgets('catalogue vide : le geste est d\'en créer un', (tester) async {
    when(() => getCatalog(any())).thenAnswer(
      (_) async => const Right(BoutiqueCatalog(articles: [], withheld: false)),
    );

    await pumpPage(tester);

    expect(find.text('Aucun article au catalogue'), findsOneWidget);
    expect(find.text('Catalogue non communiqué'), findsNothing);
  });

  testWidgets('échec de lecture : l\'écran ENTIER passe en erreur', (
    tester,
  ) async {
    when(
      () => getCatalog(any()),
    ).thenAnswer((_) async => const Left(StorageFailure('illisible')));

    await pumpPage(tester);

    expect(find.text('Catalogue illisible'), findsOneWidget);
    expect(find.byType(BoutiqueArticleCard), findsNothing);
  });

  group('après encaissement', () {
    /// Un panier prêt, posé dans l'état du bloc : le parcours complet passe par
    /// la modale de confirmation, qui a son propre test.
    BoutiqueState collected() => const BoutiqueState(
      status: BoutiqueStatus.ready,
      catalog: BoutiqueCatalog(articles: [_polo], withheld: false),
      recordedSale: RecordedSale(
        sale: BoutiqueSaleLocalModel(
          id: 'aaaabbbb-cccc-dddd',
          schoolId: 'E1',
          academicYearId: 'ay-1',
          payerLastName: 'Ndombo',
          totalInCents: 3500,
          currency: 'USD',
          soldAt: '2026-08-29T11:42:00Z',
          updatedAt: 0,
        ),
        lines: [],
      ),
    );

    testWidgets('la barre de reçu remplace le pied, panier INTACT', (
      tester,
    ) async {
      // Le panier reste derrière : il permet de réimprimer sans recomposer, et
      // évite qu'un doigt malheureux efface la vente qu'on remet.
      await pumpPage(tester, seed: collected());

      expect(find.textContaining('Vente encaissée'), findsOneWidget);
      expect(find.text('Imprimer'), findsOneWidget);
      expect(find.text('Nouvelle vente'), findsOneWidget);
    });

    testWidgets('le pied ne propose plus NI encaisser NI vider', (
      tester,
    ) async {
      // Le panier reste intact après l'encaissement (pour réimprimer), donc
      // `canCollect` reste vrai. Sans neutralisation, le guichet appuierait sur
      // « Encaisser » et rien ne se produirait — le bloc refuse en silence.
      await pumpPage(tester, seed: collected());

      final collect = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Encaisser en espèces'),
      );
      expect(collect.onPressed, isNull);
      // Et vider effacerait ce que la barre de reçu sert à réimprimer.
      expect(find.text('Vider le panier'), findsNothing);
    });

    testWidgets('sans numéro, le sous-titre annonce le PROVISOIRE', (
      tester,
    ) async {
      // Un ticket provisoire et un reçu scellé se ressemblent au comptoir :
      // c'est le seul endroit où l'écran peut lever le doute.
      await pumpPage(tester, seed: collected());

      expect(find.textContaining('provisoire'), findsOneWidget);
    });
  });
}
