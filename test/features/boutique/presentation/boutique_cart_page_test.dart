import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/find_boutique_payer_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/record_boutique_sale_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/pages/boutique_cart_page.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_panel.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_clear_cart_dialog.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_success_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetCatalog extends Mock implements GetBoutiqueCatalogUseCase {}

class _MockFindPayer extends Mock implements FindBoutiquePayerUseCase {}

class _MockRecordSale extends Mock implements RecordBoutiqueSaleUseCase {}

class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'k${_n++}';
}

/// Un bloc dont l'état de départ est imposé — la composition du panier a ses
/// propres tests, et la rejouer ici n'apprendrait rien de l'encaissement.
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

/// Prix plat : la ligne est résolue sans qu'aucun niveau soit désigné.
const _cahier = BoutiqueArticle(
  id: 'art-cahier',
  academicYearId: 'ay-1',
  code: 'CAH',
  label: 'Cahier 100 pages',
  family: ArticleFamily.fournitures,
  pricingMode: PricingMode.prixUnique,
  unitPriceInCents: 1500,
  currency: 'USD',
);

const _recorded = RecordedSale(
  sale: BoutiqueSaleLocalModel(
    id: 'aaaabbbb-cccc-dddd',
    schoolId: 'E1',
    academicYearId: 'ay-1',
    payerLastName: 'Ndombo',
    soldAt: '2026-08-29T11:42:00Z',
    updatedAt: 0,
  ),
  lines: [],
);

void main() {
  late _MockGetCatalog getCatalog;
  late _MockFindPayer findPayer;
  late _MockRecordSale recordSale;

  setUpAll(() => registerFallbackValue(const BoutiqueCart()));

  setUp(() {
    getCatalog = _MockGetCatalog();
    findPayer = _MockFindPayer();
    recordSale = _MockRecordSale();
    when(() => findPayer(any())).thenAnswer((_) async => null);
    when(() => getCatalog(any())).thenAnswer(
      (_) async =>
          const Right(BoutiqueCatalog(articles: [_cahier], withheld: false)),
    );
  });

  /// Un panier prêt à encaisser : une ligne tarifée, un payeur complet.
  BoutiqueState ready() {
    final cart = const BoutiqueCart()
        .addArticle(_cahier, keyOf: () => 'line-1')
        .withPayer(
          const CartPayer(
            lastName: 'Ndombo',
            middleName: 'Lelo',
            firstName: 'Willy',
            phoneNumber: '+243810220145',
          ),
        );
    return BoutiqueState(
      status: BoutiqueStatus.ready,
      catalog: const BoutiqueCatalog(articles: [_cahier], withheld: false),
      cart: cart,
    );
  }

  /// Monte le panier **poussé depuis un écran d'accueil** : c'est la seule façon
  /// d'observer qu'il se referme sur le catalogue une fois la vente close.
  Future<BoutiqueBloc> pumpCartPage(
    WidgetTester tester, {
    required BoutiqueState seed,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final bloc = _SeededBloc(
      getCatalog: getCatalog,
      findPayer: findPayer,
      recordSale: recordSale,
      ids: _SeqIds(),
      seed: seed,
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => BoutiqueCartPage.push(
                  context,
                  bloc: bloc,
                  academicYearId: 'ay-1',
                  levels: const [],
                ),
                child: const Text('CATALOGUE'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('CATALOGUE'));
    await tester.pumpAndSettle();
    return bloc;
  }

  /// Encaisse pour de vrai : bouton, puis récapitulatif non modifiable.
  Future<void> collect(WidgetTester tester) async {
    await tester.tap(find.text('Encaisser en espèces'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Encaisser 15'));
    await tester.pumpAndSettle();
  }

  testWidgets('le panier s\'ouvre en PAGE, avec son panneau', (tester) async {
    await pumpCartPage(tester, seed: ready());

    expect(find.byType(BoutiqueCartPage), findsOneWidget);
    expect(find.byType(BoutiqueCartPanel), findsOneWidget);
    expect(find.text('Cahier 100 pages'), findsOneWidget);
  });

  testWidgets('l\'encaissement réussi ouvre la modale de succès', (
    tester,
  ) async {
    // C'est là que le guichet apprend que c'est fini — et non dans une barre
    // qui se glisse au-dessus d'un panier encore à l'écran.
    when(
      () => recordSale(
        cart: any(named: 'cart'),
        academicYearId: any(named: 'academicYearId'),
        cashierName: any(named: 'cashierName'),
      ),
    ).thenAnswer((_) async => const Right(_recorded));

    await pumpCartPage(tester, seed: ready());
    await collect(tester);

    expect(find.byType(BoutiqueSaleSuccessDialog), findsOneWidget);
    expect(find.text('Vente encaissée'), findsOneWidget);
    expect(find.text('Imprimer'), findsOneWidget);
  });

  testWidgets('sans numéro de reçu, la modale annonce le PROVISOIRE', (
    tester,
  ) async {
    // Un ticket provisoire et un reçu scellé se ressemblent au comptoir : c'est
    // le seul endroit où l'écran peut lever le doute.
    when(
      () => recordSale(
        cart: any(named: 'cart'),
        academicYearId: any(named: 'academicYearId'),
        cashierName: any(named: 'cashierName'),
      ),
    ).thenAnswer((_) async => const Right(_recorded));

    await pumpCartPage(tester, seed: ready());
    await collect(tester);

    expect(find.textContaining('provisoire'), findsOneWidget);
  });

  testWidgets('« Terminer » vide le panier ET rend le catalogue', (
    tester,
  ) async {
    // Le panier n'est vidé qu'ICI : plus tôt, il effacerait ce que le ticket
    // sert justement à imprimer.
    when(
      () => recordSale(
        cart: any(named: 'cart'),
        academicYearId: any(named: 'academicYearId'),
        cashierName: any(named: 'cashierName'),
      ),
    ).thenAnswer((_) async => const Right(_recorded));

    final bloc = await pumpCartPage(tester, seed: ready());
    await collect(tester);

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(bloc.state.cart.isEmpty, isTrue);
    expect(bloc.state.recordedSale, isNull);
    expect(find.byType(BoutiqueCartPage), findsNothing);
    expect(find.text('CATALOGUE'), findsOneWidget);
  });

  group('vider le panier', () {
    /// Le geste vit au bas du panier, hors de vue : taper sans l'amener à
    /// l'écran ne toucherait rien, et le test verdirait sur un panier jamais
    /// vidé.
    Future<void> tapClear(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Vider le panier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vider le panier'));
      await tester.pumpAndSettle();
    }

    testWidgets('le geste DEMANDE confirmation, et nomme ce qui se perd', (
      tester,
    ) async {
      // « Êtes-vous sûr ? » ne dit rien de ce qu'on s'apprête à perdre, et se
      // répond au hasard : la modale cite les articles et le payeur saisi.
      final bloc = await pumpCartPage(tester, seed: ready());
      await tapClear(tester);

      expect(find.byType(BoutiqueClearCartDialog), findsOneWidget);
      expect(find.text('1 article au panier'), findsOneWidget);
      expect(find.textContaining('Ndombo Lelo Willy'), findsWidgets);
      // Rien n'a bougé tant qu'on n'a pas répondu.
      expect(bloc.state.cart.isEmpty, isFalse);
    });

    testWidgets('refuser GARDE le panier', (tester) async {
      final bloc = await pumpCartPage(tester, seed: ready());
      await tapClear(tester);

      await tester.tap(find.text('Garder le panier'));
      await tester.pumpAndSettle();

      expect(find.byType(BoutiqueClearCartDialog), findsNothing);
      expect(bloc.state.cart.isEmpty, isFalse);
      expect(bloc.state.cart.payer.lastName, 'Ndombo');
    });

    testWidgets('confirmer vide les lignes ET le payeur', (tester) async {
      // Le payeur doit suivre : sinon l'identité de la vente précédente
      // resterait affichée sur la suivante.
      final bloc = await pumpCartPage(tester, seed: ready());
      await tapClear(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Vider'));
      await tester.pumpAndSettle();

      expect(bloc.state.cart.isEmpty, isTrue);
      expect(bloc.state.cart.payer.lastName, isEmpty);
      expect(find.text('Ndombo Lelo Willy'), findsNothing);
    });
  });

  testWidgets('une vente refusée garde le panier ET la page', (tester) async {
    // L'écriture est atomique : un échec n'a RIEN posé. Fermer la page ferait
    // croire à une vente passée, et vider le panier ferait tout recomposer.
    when(
      () => recordSale(
        cart: any(named: 'cart'),
        academicYearId: any(named: 'academicYearId'),
        cashierName: any(named: 'cashierName'),
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('disque plein')));

    final bloc = await pumpCartPage(tester, seed: ready());
    await collect(tester);

    expect(find.byType(BoutiqueSaleSuccessDialog), findsNothing);
    expect(find.byType(BoutiqueCartPage), findsOneWidget);
    expect(bloc.state.cart.isEmpty, isFalse);
  });
}
