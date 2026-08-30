import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sales_history_period.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_history_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_history_bloc.dart';

class _MockGetHistory extends Mock implements GetBoutiqueSalesHistoryUseCase {}

SaleHistoryEntry _sale({
  String id = 's-1',
  int total = 1500,
  String currency = 'USD',
  String syncStatus = 'SYNCED',
}) => SaleHistoryEntry(
  id: id,
  payerName: 'Ndombo Lelo Willy',
  totalInCents: total,
  currency: currency,
  soldAt: '2026-08-30T09:00:00Z',
  syncStatus: syncStatus,
  articleCount: 2,
);

void main() {
  late _MockGetHistory getHistory;

  setUp(() {
    getHistory = _MockGetHistory();
    registerFallbackValue(SalesHistoryPeriod.day);
  });

  BoutiqueHistoryBloc build() => BoutiqueHistoryBloc(getHistory: getHistory);

  void answer(List<SaleHistoryEntry> sales) => when(
    () => getHistory(
      academicYearId: any(named: 'academicYearId'),
      period: any(named: 'period'),
    ),
  ).thenAnswer((_) async => Right(sales));

  test('la fenêtre par DÉFAUT est la caisse du jour', () {
    // C'est ce qu'on vient vérifier au guichet ; ouvrir sur l'année ferait
    // défiler des mois pour trouver la vente d'il y a deux minutes.
    expect(build().state.period, SalesHistoryPeriod.day);
  });

  blocTest<BoutiqueHistoryBloc, BoutiqueHistoryState>(
    'la lecture passe par chargement puis rend les ventes',
    setUp: () => answer([_sale()]),
    build: build,
    act: (bloc) => bloc.add(const BoutiqueHistoryRequested('ay-1')),
    expect: () => [
      isA<BoutiqueHistoryState>().having(
        (s) => s.status,
        'status',
        HistoryStatus.loading,
      ),
      isA<BoutiqueHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.ready)
          .having((s) => s.sales, 'sales', hasLength(1)),
    ],
  );

  blocTest<BoutiqueHistoryBloc, BoutiqueHistoryState>(
    'changer de fenêtre la POSE avant de lire',
    // Sans cela, un tapotement rapide laisserait l'écran marquer une fenêtre et
    // en afficher une autre.
    setUp: () => answer(const []),
    build: build,
    act: (bloc) => bloc.add(
      const BoutiqueHistoryPeriodChanged(
        academicYearId: 'ay-1',
        period: SalesHistoryPeriod.month,
      ),
    ),
    expect: () => [
      isA<BoutiqueHistoryState>()
          .having((s) => s.period, 'period', SalesHistoryPeriod.month)
          .having((s) => s.status, 'status', isNot(HistoryStatus.loading)),
      isA<BoutiqueHistoryState>()
          .having((s) => s.period, 'period', SalesHistoryPeriod.month)
          .having((s) => s.status, 'status', HistoryStatus.loading),
      isA<BoutiqueHistoryState>()
          .having((s) => s.period, 'period', SalesHistoryPeriod.month)
          .having((s) => s.status, 'status', HistoryStatus.ready),
    ],
  );

  blocTest<BoutiqueHistoryBloc, BoutiqueHistoryState>(
    'une base illisible n\'est PAS une caisse vide',
    // Dire « aucune vente » à un guichet qui vient d'en encaisser trois serait
    // pire qu'une erreur.
    setUp: () => when(
      () => getHistory(
        academicYearId: any(named: 'academicYearId'),
        period: any(named: 'period'),
      ),
    ).thenAnswer((_) async => const Left(StorageFailure('illisible'))),
    build: build,
    act: (bloc) => bloc.add(const BoutiqueHistoryRequested('ay-1')),
    skip: 1,
    expect: () => [
      isA<BoutiqueHistoryState>()
          .having((s) => s.status, 'status', HistoryStatus.failure)
          .having((s) => s.failure, 'failure', isA<StorageFailure>()),
    ],
  );

  test('le total est rendu PAR DEVISE, jamais additionné', () {
    // Additionner des dollars et des francs donnerait un nombre qui ne veut
    // rien dire, et un guichet le lirait comme un montant.
    final state = BoutiqueHistoryState(
      sales: [
        _sale(id: 's-1', total: 1500),
        _sale(id: 's-2', total: 2500),
        _sale(id: 's-3', total: 400000, currency: 'CDF'),
      ],
    );

    expect(state.totalsByCurrency, {'USD': 4000, 'CDF': 400000});
  });

  test('les ventes NON PARTIES se comptent à part', () {
    final state = BoutiqueHistoryState(
      sales: [
        _sale(id: 's-1'),
        _sale(id: 's-2', syncStatus: 'PENDING_SYNC'),
        _sale(id: 's-3', syncStatus: 'PENDING_SYNC'),
      ],
    );

    expect(state.pendingCount, 2);
  });
}
