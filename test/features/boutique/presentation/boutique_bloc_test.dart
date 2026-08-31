import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_cart.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_payer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/find_boutique_payer_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/record_boutique_sale_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';

class _MockGetCatalog extends Mock implements GetBoutiqueCatalogUseCase {}

class _MockFindPayer extends Mock implements FindBoutiquePayerUseCase {}

class _MockRecordSale extends Mock implements RecordBoutiqueSaleUseCase {}

/// Générateur déterministe : le test ne doit pas deviner un uuid.
class _SeqIds implements IdGenerator {
  int _n = 0;

  @override
  String newId() => 'k${_n++}';
}

BoutiqueArticle _article(
  String id, {
  String label = 'Article',
  ArticleFamily? family = ArticleFamily.uniforme,
  PricingMode? mode = PricingMode.prixUnique,
}) => BoutiqueArticle(
  id: id,
  academicYearId: 'ay-1',
  code: id.toUpperCase(),
  label: label,
  family: family,
  pricingMode: mode,
  unitPriceInCents: mode == PricingMode.prixUnique ? 1000 : null,
  levelPrices: mode == PricingMode.prixParNiveau
      ? const {'primaire': 1000}
      : const {},
  currency: 'USD',
);

BoutiqueCatalog _catalog(List<BoutiqueArticle> articles) =>
    BoutiqueCatalog(articles: articles, withheld: false);

const _recorded = RecordedSale(
  sale: BoutiqueSaleLocalModel(
    id: 'vente-1',
    schoolId: 'E1',
    academicYearId: 'ay-1',
    payerLastName: 'Ndombo',
    soldAt: '2026-08-29T11:42:00Z',
    updatedAt: 0,
  ),
  lines: [],
);

const _known = BoutiquePayer(
  lastName: 'Ndombo',
  middleName: 'Lelo',
  firstName: 'Willy',
  phoneNumber: '+243810220145',
  saleCount: 3,
);

void main() {
  late _MockGetCatalog getCatalog;
  late _MockFindPayer findPayer;
  late _MockRecordSale recordSale;

  BoutiqueBloc build() => BoutiqueBloc(
    getCatalog: getCatalog,
    findPayer: findPayer,
    recordSale: recordSale,
    ids: _SeqIds(),
  );

  setUpAll(() => registerFallbackValue(const BoutiqueCart()));

  setUp(() {
    getCatalog = _MockGetCatalog();
    findPayer = _MockFindPayer();
    recordSale = _MockRecordSale();
    when(() => findPayer(any())).thenAnswer((_) async => null);
    when(
      () => recordSale(
        cart: any(named: 'cart'),
        academicYearId: any(named: 'academicYearId'),
        cashierName: any(named: 'cashierName'),
      ),
    ).thenAnswer((_) async => const Right(_recorded));
    when(() => getCatalog(any())).thenAnswer(
      (_) async => Right(_catalog([_article('polo', label: 'Polo')])),
    );
  });

  blocTest<BoutiqueBloc, BoutiqueState>(
    'le catalogue se charge',
    build: build,
    act: (bloc) => bloc.add(const BoutiqueCatalogRequested('ay-1')),
    expect: () => [
      isA<BoutiqueState>().having(
        (s) => s.status,
        'status',
        BoutiqueStatus.loading,
      ),
      isA<BoutiqueState>()
          .having((s) => s.status, 'status', BoutiqueStatus.ready)
          .having((s) => s.catalog.articles, 'articles', hasLength(1)),
    ],
  );

  blocTest<BoutiqueBloc, BoutiqueState>(
    'un échec de lecture passe l\'écran ENTIER en erreur',
    build: build,
    setUp: () => when(
      () => getCatalog(any()),
    ).thenAnswer((_) async => const Left(StorageFailure('illisible'))),
    act: (bloc) => bloc.add(const BoutiqueCatalogRequested('ay-1')),
    expect: () => [
      isA<BoutiqueState>().having(
        (s) => s.status,
        'status',
        BoutiqueStatus.loading,
      ),
      isA<BoutiqueState>()
          .having((s) => s.status, 'status', BoutiqueStatus.failure)
          .having((s) => s.failure, 'failure', isA<StorageFailure>()),
    ],
  );

  blocTest<BoutiqueBloc, BoutiqueState>(
    'RECHARGER le catalogue ne fait PAS perdre le panier',
    // Une vente en composition ne se perd pas parce qu'un pull est passé —
    // c'est ce qui distingue un rechargement d'un « Nouvelle vente ».
    build: build,
    act: (bloc) async {
      bloc.add(const BoutiqueCatalogRequested('ay-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(BoutiqueArticleAdded(_article('polo')));
      bloc.add(const BoutiqueCatalogRequested('ay-1'));
    },
    skip: 3,
    expect: () => [
      isA<BoutiqueState>().having((s) => s.cart.lines, 'lignes', hasLength(1)),
      isA<BoutiqueState>()
          .having((s) => s.status, 'status', BoutiqueStatus.ready)
          .having((s) => s.cart.lines, 'lignes conservées', hasLength(1)),
    ],
  );

  blocTest<BoutiqueBloc, BoutiqueState>(
    'un article INVENDABLE n\'entre pas au panier',
    // Mode de tarification inconnu : il y porterait un prix nul que rien ne
    // pourrait résoudre, et bloquerait l'encaissement sans issue.
    build: build,
    act: (bloc) => bloc.add(BoutiqueArticleAdded(_article('x', mode: null))),
    expect: () => <BoutiqueState>[],
  );

  group('recherche et filtres', () {
    setUp(() {
      when(() => getCatalog(any())).thenAnswer(
        (_) async => Right(
          _catalog([
            _article('polo', label: 'Polo Lacoste'),
            _article(
              'cahier',
              label: 'Journal de classe',
              family: ArticleFamily.fournitures,
            ),
          ]),
        ),
      );
    });

    blocTest<BoutiqueBloc, BoutiqueState>(
      'la recherche porte sur le libellé ET le code',
      build: build,
      act: (bloc) async {
        bloc.add(const BoutiqueCatalogRequested('ay-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BoutiqueQueryChanged('CAHIER'));
      },
      skip: 2,
      verify: (bloc) {
        expect(bloc.state.visibleByFamily.keys, [ArticleFamily.fournitures]);
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'une famille vidée par le filtre ne laisse aucun intitulé',
      build: build,
      act: (bloc) async {
        bloc.add(const BoutiqueCatalogRequested('ay-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BoutiqueFamilyFilterChanged(ArticleFamily.fournitures));
      },
      skip: 2,
      verify: (bloc) {
        expect(bloc.state.visibleByFamily.keys, [ArticleFamily.fournitures]);
        expect(
          bloc.state.visibleByFamily.containsKey(ArticleFamily.uniforme),
          isFalse,
        );
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'aucun résultat se distingue d\'un catalogue vide',
      build: build,
      act: (bloc) async {
        bloc.add(const BoutiqueCatalogRequested('ay-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BoutiqueQueryChanged('introuvable'));
      },
      skip: 2,
      verify: (bloc) {
        expect(bloc.state.hasNoMatch, isTrue);
        expect(bloc.state.catalog.isEmpty, isFalse);
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'réinitialiser vide la recherche ET repasse à « Toutes »',
      build: build,
      act: (bloc) async {
        bloc.add(const BoutiqueCatalogRequested('ay-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BoutiqueQueryChanged('polo'));
        bloc.add(const BoutiqueFamilyFilterChanged(ArticleFamily.uniforme));
        bloc.add(const BoutiqueFiltersReset());
      },
      skip: 4,
      verify: (bloc) {
        expect(bloc.state.hasActiveFilters, isFalse);
        expect(bloc.state.visibleByFamily, hasLength(2));
      },
    );
  });

  group('payeur et répertoire', () {
    blocTest<BoutiqueBloc, BoutiqueState>(
      'un numéro TROP COURT ne déclenche aucune recherche',
      // On ne juge pas un numéro à moitié tapé : chercher sur trois chiffres
      // remonterait la moitié du répertoire.
      build: build,
      act: (bloc) =>
          bloc.add(const BoutiquePayerChanged(CartPayer(phoneNumber: '0810'))),
      verify: (_) => verifyNever(() => findPayer(any())),
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'un numéro exploitable interroge le répertoire',
      build: build,
      setUp: () => when(() => findPayer(any())).thenAnswer((_) async => _known),
      act: (bloc) => bloc.add(
        const BoutiquePayerChanged(CartPayer(phoneNumber: '+243810220145')),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.payerMatch, _known);
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'changer le numéro EFFACE la proposition précédente',
      // Elle appartenait au numéro qui l'a produite : la garder ferait offrir
      // « Utiliser » sur un payeur qui n'est plus celui du numéro affiché.
      build: build,
      seed: () => const BoutiqueState(payerMatch: _known),
      act: (bloc) => bloc.add(
        const BoutiquePayerChanged(CartPayer(phoneNumber: '+243810220')),
      ),
      verify: (bloc) {
        expect(bloc.state.payerMatch, isNull);
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'corriger le NOM ne relance pas la recherche',
      // Seul le téléphone est la clé ; relancer à chaque frappe de nom
      // interrogerait la base pour rien.
      build: build,
      seed: () => const BoutiqueState(
        cart: BoutiqueCart(payer: CartPayer(phoneNumber: '+243810220145')),
      ),
      act: (bloc) => bloc.add(
        const BoutiquePayerChanged(
          CartPayer(phoneNumber: '+243810220145', lastName: 'Ndombu'),
        ),
      ),
      verify: (_) => verifyNever(() => findPayer(any())),
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'un résultat PÉRIMÉ n\'est jamais appliqué',
      // Le guichet a continué de taper pendant la lecture : appliquer le
      // résultat proposerait le payeur d'un numéro qu'il vient de corriger.
      build: build,
      setUp: () {
        when(() => findPayer('+243810220145')).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _known;
        });
        when(() => findPayer('+243810220146')).thenAnswer((_) async => null);
      },
      act: (bloc) async {
        bloc.add(
          const BoutiquePayerChanged(CartPayer(phoneNumber: '+243810220145')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(
          const BoutiquePayerChanged(CartPayer(phoneNumber: '+243810220146')),
        );
      },
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        expect(bloc.state.payerMatch, isNull);
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      '« Utiliser » remplit le bloc et NORMALISE le numéro',
      // Laisser deux écritures du même numéro ferait deux payeurs à la
      // prochaine recherche.
      build: build,
      act: (bloc) => bloc.add(
        const BoutiquePayerFromDirectoryUsed(
          BoutiquePayer(
            lastName: 'Ndombo',
            middleName: 'Lelo',
            firstName: 'Willy',
            phoneNumber: '0810220145',
          ),
        ),
      ),
      verify: (bloc) {
        final payer = bloc.state.cart.payer;
        expect(payer.lastName, 'Ndombo');
        expect(payer.knownFromDirectory, isTrue);
        expect(payer.phoneNumber, '+243810220145');
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'vider le panier emporte AUSSI la proposition',
      build: build,
      seed: () => const BoutiqueState(payerMatch: _known),
      act: (bloc) => bloc.add(const BoutiqueCartCleared()),
      verify: (bloc) {
        expect(bloc.state.payerMatch, isNull);
        expect(bloc.state.cart.payer, const CartPayer());
      },
    );
  });

  group('encaissement', () {
    /// Un panier prêt : payeur complet, une ligne à prix résolu.
    BoutiqueCart readyCart() => const BoutiqueCart(
      payer: CartPayer(
        lastName: 'Ndombo',
        middleName: 'Lelo',
        firstName: 'Willy',
        phoneNumber: '+243810220145',
      ),
      lines: [
        CartLine(
          key: 'k0',
          article: BoutiqueArticle(
            id: 'art-ecu',
            academicYearId: 'ay-1',
            code: 'ECUS',
            label: 'Écusson',
            family: ArticleFamily.uniforme,
            pricingMode: PricingMode.prixUnique,
            unitPriceInCents: 1000,
            currency: 'USD',
          ),
        ),
      ],
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'encaisser écrit la vente et la garde à l\'écran',
      build: build,
      seed: () => BoutiqueState(cart: readyCart()),
      act: (bloc) =>
          bloc.add(const BoutiqueSaleSubmitted(academicYearId: 'ay-1')),
      verify: (bloc) {
        expect(bloc.state.recordedSale, isNotNull);
        // Le panier N'EST PAS vidé : il reste jusqu'à « Nouvelle vente », ce
        // qui permet de réimprimer sans recomposer.
        expect(bloc.state.cart.lines, hasLength(1));
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'un panier NON prêt n\'encaisse rien',
      build: build,
      // Payeur vide : le pied nomme les manques, et rien ne doit partir.
      seed: () => const BoutiqueState(),
      act: (bloc) =>
          bloc.add(const BoutiqueSaleSubmitted(academicYearId: 'ay-1')),
      verify: (_) => verifyNever(
        () => recordSale(
          cart: any(named: 'cart'),
          academicYearId: any(named: 'academicYearId'),
          cashierName: any(named: 'cashierName'),
        ),
      ),
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      '💀 deux appuis rapides ne créent QU\'UNE vente',
      // Sans ce verrou, deux uuid partiraient, et l'argent figurerait deux fois
      // dans les livres.
      build: build,
      seed: () => BoutiqueState(cart: readyCart()),
      act: (bloc) {
        bloc.add(const BoutiqueSaleSubmitted(academicYearId: 'ay-1'));
        bloc.add(const BoutiqueSaleSubmitted(academicYearId: 'ay-1'));
      },
      verify: (_) {
        verify(
          () => recordSale(
            cart: any(named: 'cart'),
            academicYearId: any(named: 'academicYearId'),
            cashierName: any(named: 'cashierName'),
          ),
        ).called(1);
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      '💀 une vente déjà encaissée ne se réencaisse pas',
      build: build,
      seed: () => BoutiqueState(cart: readyCart(), recordedSale: _recorded),
      act: (bloc) =>
          bloc.add(const BoutiqueSaleSubmitted(academicYearId: 'ay-1')),
      verify: (_) => verifyNever(
        () => recordSale(
          cart: any(named: 'cart'),
          academicYearId: any(named: 'academicYearId'),
          cashierName: any(named: 'cashierName'),
        ),
      ),
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      'un échec d\'écriture laisse le panier INTACT',
      // Rien n'a été posé : le guichet réessaie sans risque de double vente, et
      // l'écran ne bascule pas en erreur pleine page sur une vente composée.
      build: build,
      setUp: () => when(
        () => recordSale(
          cart: any(named: 'cart'),
          academicYearId: any(named: 'academicYearId'),
          cashierName: any(named: 'cashierName'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure('disque plein'))),
      seed: () => BoutiqueState(cart: readyCart()),
      act: (bloc) =>
          bloc.add(const BoutiqueSaleSubmitted(academicYearId: 'ay-1')),
      verify: (bloc) {
        expect(bloc.state.saleFailure, isA<StorageFailure>());
        expect(bloc.state.recordedSale, isNull);
        expect(bloc.state.cart.lines, hasLength(1));
        expect(bloc.state.isCollecting, isFalse);
      },
    );

    blocTest<BoutiqueBloc, BoutiqueState>(
      '« Nouvelle vente » vide tout et garde l\'écran',
      build: build,
      seed: () => BoutiqueState(cart: readyCart(), recordedSale: _recorded),
      act: (bloc) => bloc.add(const BoutiqueNewSaleStarted()),
      verify: (bloc) {
        expect(bloc.state.cart.isEmpty, isTrue);
        expect(bloc.state.cart.payer, const CartPayer());
        expect(bloc.state.recordedSale, isNull);
      },
    );
  });
}
