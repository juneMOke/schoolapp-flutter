import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/sale_receipt_watch_cubit.dart';

class _MockGetDetail extends Mock implements GetBoutiqueSaleDetailUseCase {}

RecordedSale _sale({String? number}) => RecordedSale(
  sale: BoutiqueSaleLocalModel(
    id: 's-1',
    schoolId: 'E1',
    academicYearId: 'ay-1',
    soldAt: '2026-11-17T08:00:00Z',
    receiptNumber: number,
    updatedAt: 0,
  ),
  lines: const [],
);

/// Le guet du numéro du reçu de vente : le ticket ne sort qu'avec lui.
void main() {
  late _MockGetDetail getDetail;

  setUp(() => getDetail = _MockGetDetail());

  SaleReceiptWatchCubit cubit() => SaleReceiptWatchCubit(
    getDetail,
    every: const Duration(milliseconds: 5),
    giveUpAfter: const Duration(milliseconds: 20),
  );

  test('une vente déjà numérotée est rendue tout de suite', () async {
    final watch = cubit();
    addTearDown(watch.close);

    await watch.watch(_sale(number: 'ETL-RV-1'));

    expect(watch.state.phase, SaleReceiptPhase.numbered);
    expect(watch.state.receiptNumber, 'ETL-RV-1');
    verifyNever(() => getDetail(any()));
  });

  test('le numéro posé par l\'ACK est trouvé à la relecture', () async {
    var reads = 0;
    when(() => getDetail('s-1')).thenAnswer((_) async {
      reads++;
      return Right(
        SaleDetail(sale: _sale(number: reads >= 2 ? 'ETL-RV-2' : null)),
      );
    });
    final watch = cubit();
    addTearDown(watch.close);

    await watch.watch(_sale());
    expect(watch.state.phase, SaleReceiptPhase.waiting);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(watch.state.phase, SaleReceiptPhase.numbered);
    // C'est la vente RELUE qui s'imprime : elle porte le numéro.
    expect(watch.state.sale?.sale.receiptNumber, 'ETL-RV-2');
  });

  test('sans numéro dans le délai, le guet renonce', () async {
    when(
      () => getDetail('s-1'),
    ).thenAnswer((_) async => Right(SaleDetail(sale: _sale())));
    final watch = cubit();
    addTearDown(watch.close);

    await watch.watch(_sale());
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(watch.state.phase, SaleReceiptPhase.deferred);
    expect(watch.state.sale?.id, 's-1');
  });

  test('tant que le numéro manque, la synchro est relancée', () async {
    // La marque « reçu manquant » naît pendant le flush qui applique l'ACK :
    // sans relance, elle attendrait le battement suivant.
    when(
      () => getDetail('s-1'),
    ).thenAnswer((_) async => Right(SaleDetail(sale: _sale())));
    var nudges = 0;
    final watch = SaleReceiptWatchCubit(
      getDetail,
      every: const Duration(milliseconds: 5),
      giveUpAfter: const Duration(milliseconds: 20),
      nudge: () async => nudges++,
    );
    addTearDown(watch.close);

    await watch.watch(_sale());
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(nudges, greaterThan(1));
  });

  test('une relance qui lève ne casse pas le guet', () async {
    when(
      () => getDetail('s-1'),
    ).thenAnswer((_) async => Right(SaleDetail(sale: _sale())));
    final watch = SaleReceiptWatchCubit(
      getDetail,
      every: const Duration(milliseconds: 5),
      giveUpAfter: const Duration(milliseconds: 20),
      nudge: () async => throw StateError('réseau'),
    );
    addTearDown(watch.close);

    await watch.watch(_sale());
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(watch.state.phase, SaleReceiptPhase.deferred);
  });

  test('une relecture en échec ne vaut pas un numéro', () async {
    when(
      () => getDetail('s-1'),
    ).thenAnswer((_) async => const Left(StorageFailure('base')));
    final watch = cubit();
    addTearDown(watch.close);

    await watch.watch(_sale());
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(watch.state.phase, SaleReceiptPhase.deferred);
  });

  test('refermé, il ne relit plus', () async {
    when(
      () => getDetail('s-1'),
    ).thenAnswer((_) async => Right(SaleDetail(sale: _sale())));
    final watch = cubit();

    await watch.watch(_sale());
    await watch.close();
    clearInteractions(getDetail);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    verifyNever(() => getDetail(any()));
  });
}
