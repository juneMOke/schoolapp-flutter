import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_till_receipts_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';

class MockGetTillReceiptsUseCase extends Mock
    implements GetTillReceiptsUseCase {}

TillReceipt _receipt(String id, String currency) => TillReceipt(
  paymentId: id,
  paidAt: DateTime.utc(2026, 5, 15, 9),
  source: 'FACTURATION',
  amount: 24000,
  currency: currency,
  receiptNumber: 'ETL-RC-2526-000184',
);

TillReceiptsPage _page({
  int page = 0,
  int totalPages = 3,
  int withoutReceiptNumber = 2,
  List<TillReceipt>? content,
}) => TillReceiptsPage(
  content: content ?? [_receipt('p1', 'USD')],
  page: page,
  size: 8,
  totalElements: 17,
  totalPages: totalPages,
  withoutReceiptNumber: withoutReceiptNumber,
);

/// La table des reçus — **le second appel**.
///
/// Ce qui se vérifie ici n'est pas le rendu des lignes, mais **ce que le BLoC
/// refuse de décider** : il ne choisit ni la fenêtre, ni la caisse, et il ne
/// garde jamais une page qui ne décrit plus ce qu'on regarde.
void main() {
  setUpAll(() {
    registerFallbackValue(const TillWindow.day());
  });

  late MockGetTillReceiptsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetTillReceiptsUseCase();
  });

  FinanceTillReceiptsBloc buildBloc() =>
      FinanceTillReceiptsBloc(getTillReceiptsUseCase: mockUseCase);

  void stub(TillReceiptsPage page) {
    when(
      () => mockUseCase(
        currency: any(named: 'currency'),
        window: any(named: 'window'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Right(page));
  }

  group('le chargement', () {
    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'la devise et la fenêtre sont REÇUES, jamais choisies ici',
      setUp: () => stub(_page()),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FinanceTillReceiptsRequested(
          currency: 'CDF',
          window: TillWindow.month(),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.currency, 'CDF');
        expect(bloc.state.window, const TillWindow.month());
        verify(
          () => mockUseCase(
            currency: 'CDF',
            window: const TillWindow.month(),
            page: 0,
            size: any(named: 'size'),
          ),
        ).called(1);
      },
    );

    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'le compteur de rattrapages descend tel quel — portée fenêtre',
      setUp: () => stub(_page(withoutReceiptNumber: 2)),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FinanceTillReceiptsRequested(
          currency: 'USD',
          window: TillWindow.day(),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.withoutReceiptNumber, 2);
        expect(bloc.state.hasUnsealedReceipts, isTrue);
        expect(
          bloc.state.receipts,
          hasLength(1),
          reason:
              'une seule ligne sur la page, mais deux rattrapages sur la '
              'fenêtre : le compteur ne se déduit pas des lignes reçues',
        );
      },
    );

    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'une page sans ligne est un état vide, pas un succès muet',
      setUp: () => stub(_page(content: const [], totalPages: 0)),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FinanceTillReceiptsRequested(
          currency: 'USD',
          window: TillWindow.day(),
        ),
      ),
      verify: (bloc) =>
          expect(bloc.state.status, FinanceTillReceiptsStatus.empty),
    );
  });

  group('la pagination', () {
    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'changer de caisse REMET la pagination à zéro',
      setUp: () => stub(_page(page: 2)),
      build: buildBloc,
      seed: () => const FinanceTillReceiptsState(
        status: FinanceTillReceiptsStatus.success,
        currency: 'USD',
        page: 2,
      ),
      act: (bloc) => bloc.add(
        const FinanceTillReceiptsRequested(
          currency: 'CDF',
          window: TillWindow.day(),
        ),
      ),
      verify: (_) {
        // Rester page 3 en changeant de caisse afficherait une page vide d'une
        // liste qui, elle, a des lignes — et le lecteur conclurait que l'autre
        // caisse n'a rien encaissé.
        verify(
          () => mockUseCase(
            currency: 'CDF',
            window: any(named: 'window'),
            page: 0,
            size: any(named: 'size'),
          ),
        ).called(1);
      },
    );

    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'tourner une page rejoue la MÊME caisse et la MÊME fenêtre',
      setUp: () => stub(_page(page: 1)),
      build: buildBloc,
      seed: () => const FinanceTillReceiptsState(
        status: FinanceTillReceiptsStatus.success,
        currency: 'CDF',
        window: TillWindow.week(),
        page: 0,
      ),
      act: (bloc) => bloc.add(const FinanceTillReceiptsPageChanged(1)),
      verify: (_) => verify(
        () => mockUseCase(
          currency: 'CDF',
          window: const TillWindow.week(),
          page: 1,
          size: any(named: 'size'),
        ),
      ).called(1),
    );

    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'tourner une page sans caisse choisie ne demande rien',
      build: buildBloc,
      act: (bloc) => bloc.add(const FinanceTillReceiptsPageChanged(1)),
      expect: () => const <FinanceTillReceiptsState>[],
      verify: (_) => verifyNever(
        () => mockUseCase(
          currency: any(named: 'currency'),
          window: any(named: 'window'),
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ),
    );
  });

  group('l’échec', () {
    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'un 403 porte son échec tel quel — droit manquant, pas panne',
      setUp: () {
        when(
          () => mockUseCase(
            currency: any(named: 'currency'),
            window: any(named: 'window'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        ).thenAnswer(
          (_) async => const Left(UnauthorizedFailure('Access forbidden')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const FinanceTillReceiptsRequested(
          currency: 'USD',
          window: TillWindow.day(),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.status, FinanceTillReceiptsStatus.error);
        expect(
          bloc.state.failure,
          isA<UnauthorizedFailure>(),
          reason:
              'la vue doit pouvoir distinguer un refus d’une panne : les deux '
              'appellent des gestes différents',
        );
      },
    );

    blocTest<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      'un échec efface les lignes — une page périmée sous une erreur serait '
      'fausse',
      setUp: () {
        when(
          () => mockUseCase(
            currency: any(named: 'currency'),
            window: any(named: 'window'),
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure('offline')));
      },
      build: buildBloc,
      seed: () => FinanceTillReceiptsState(
        status: FinanceTillReceiptsStatus.success,
        currency: 'USD',
        receipts: [_receipt('p1', 'USD')],
      ),
      act: (bloc) => bloc.add(
        const FinanceTillReceiptsRequested(
          currency: 'USD',
          window: TillWindow.day(),
        ),
      ),
      verify: (bloc) => expect(bloc.state.receipts, isEmpty),
    );
  });
}
