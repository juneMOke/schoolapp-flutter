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
import 'package:school_app_flutter/features/boutique/domain/usecases/record_boutique_sale_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_cart_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_top_bar.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_article_card.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_button.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_panel.dart';
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

/// Le libellé le plus long du catalogue réel, sur DEUX lignes — c'est lui qui
/// fixe la hauteur de case de la grille, et une carte qui déborde de six pixels
/// raye son propre prix.
const _duplicata = BoutiqueArticle(
  id: 'art-dup',
  academicYearId: 'ay-1',
  code: 'DUPL',
  label: 'Duplicata de bulletin scolaire',
  family: ArticleFamily.actes,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 500,
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

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(1400, 1200),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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

  /// Le compte tel que la BARRE le porte. La vignette a sa propre pastille de
  /// quantité : un `find.text('1')` nu confondrait les deux, et le test
  /// passerait avec une barre muette.
  Finder countOnCartButton(String value) => find.descendant(
    of: find.byType(BoutiqueCartButton),
    matching: find.text(value),
  );

  testWidgets('un libellé sur DEUX lignes ne déborde pas de sa case', (
    tester,
  ) async {
    // `mainAxisExtent` est une hauteur FIXE : la sous-estimer ne se voit sur
    // aucun test qui n'affiche que des libellés courts, et raye le prix en
    // production.
    when(() => getCatalog(any())).thenAnswer(
      (_) async => const Right(
        BoutiqueCatalog(articles: [_polo, _duplicata], withheld: false),
      ),
    );

    await pumpPage(tester);

    expect(find.text('Duplicata de bulletin scolaire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la page se monte et rend le catalogue', (tester) async {
    // Ce test existe pour une raison précise : le sélecteur de niveau aplatit
    // `schoolLevelGroups`, dont le type se laisse inférer en `dynamic` sur une
    // liste vide littérale. L'analyse laisse alors passer un accès à un membre
    // qui n'existe pas, et l'erreur n'apparaît que sous le doigt du guichet.
    await pumpPage(tester);

    expect(find.text('Polo Lacoste'), findsOneWidget);
    expect(find.byType(BoutiqueArticleCard), findsOneWidget);
  });

  testWidgets('ajouter pose une ligne, et le panier la porte', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Ajouter au panier'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BoutiqueCartButton));
    await tester.pumpAndSettle();

    // La ligne est là, avec sa mention « Prix à résoudre » : l'article est
    // tarifé par niveau, et aucun n'a été choisi.
    expect(find.text('Prix à résoudre'), findsOneWidget);
    // Jamais grisé muet : le pied énumère ce qui manque, dans l'ordre où le
    // guichet peut le corriger.
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

  group('le panier vit AILLEURS', () {
    testWidgets('le catalogue ne porte NI panneau NI total', (tester) async {
      // Le panier a sa page. Le laisser aussi en colonne ferait deux
      // compositions du même panier, qui divergeraient sur les règles portant
      // l'argent.
      await pumpPage(tester);

      expect(find.byType(BoutiqueCartPanel), findsNothing);
      expect(find.text('Total à encaisser'), findsNothing);
    });

    testWidgets('la barre porte le panier, hors du défilement', (tester) async {
      // Posée en `appBar` du Scaffold : c'est ce qui la maintient au-dessus du
      // catalogue quel que soit le défilement. Une caisse dont le panier
      // disparaît fait recompter le guichet.
      await pumpPage(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.appBar, isA<BoutiqueTopBar>());
      expect(
        find.descendant(
          of: find.byType(BoutiqueTopBar),
          matching: find.byType(BoutiqueCartButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('taper le panier ouvre sa PAGE', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Ajouter au panier'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BoutiqueCartButton));
      await tester.pumpAndSettle();

      expect(find.byType(BoutiqueCartPage), findsOneWidget);
      // Le panier lui-même, pas une variante : une seule composition.
      expect(find.byType(BoutiqueCartPanel), findsOneWidget);
      expect(find.textContaining('À compléter :'), findsOneWidget);
    });

    testWidgets('revenir du panier ne perd RIEN', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Ajouter au panier'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BoutiqueCartButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(BoutiqueCartPage), findsNothing);
      expect(countOnCartButton('1'), findsOneWidget);
    });
  });

  group('le pas d\'ajout de la vignette', () {
    testWidgets('le bouton d\'ajout cède la place au compteur', (tester) async {
      // Le geste et son inverse au même endroit : ajouté par erreur, un article
      // se retirait auparavant en ouvrant le panier.
      await pumpPage(tester);
      expect(find.text('Ajouter au panier'), findsOneWidget);

      await tester.tap(find.text('Ajouter au panier'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter au panier'), findsNothing);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('« + » monte le compte, sur la carte ET dans la barre', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.text('Ajouter au panier'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      expect(countOnCartButton('2'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BoutiqueArticleCard),
          matching: find.text('2'),
        ),
        findsWidgets,
      );
    });

    testWidgets('« − » sur le DERNIER exemplaire rend le bouton d\'ajout', (
      tester,
    ) async {
      // Sans cela la vignette resterait bloquée sur « 1 », sans aucun moyen de
      // revenir en arrière depuis le catalogue.
      await pumpPage(tester);
      await tester.tap(find.text('Ajouter au panier'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter au panier'), findsOneWidget);
      expect(countOnCartButton('1'), findsNothing);
    });
  });
}
