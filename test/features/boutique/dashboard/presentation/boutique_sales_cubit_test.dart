import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_cubit.dart';

import '../dashboard_fixtures.dart';

class _MockSales extends Mock implements GetBoutiqueSalesUseCase {}

/// Un critère à la fois, et seul celui du mode actif part.
void main() {
  late _MockSales getSales;
  late BoutiqueSalesCubit cubit;
  final queries = <SalesQuery>[];

  setUpAll(
    () => registerFallbackValue(
      SalesQuery(academicYearId: '', window: sevenDays),
    ),
  );

  setUp(() {
    queries.clear();
    getSales = _MockSales();
    when(() => getSales(any())).thenAnswer((i) async {
      final query = i.positionalArguments.first as SalesQuery;
      queries.add(query);
      return Right(salesPageOf(total: 25, page: query.page));
    });
    cubit = BoutiqueSalesCubit(getSales: getSales);
  });
  tearDown(() => cubit.close());

  Future<void> start() => cubit.start(academicYearId: 'ay-1', window: thisWeek);

  test('au départ : toutes les ventes de la fenêtre, page 1', () async {
    await start();
    final query = queries.single;
    expect(query.window, thisWeek);
    expect(query.isFiltered, isFalse);
    expect(query.page, 0);
    expect(cubit.state.status, SalesStatus.ready);
    expect(cubit.state.page!.totalPages, 3);
  });

  test('un type d\'article choisi part seul', () async {
    await start();
    await cubit.familySelected(ArticleFamily.uniforme);
    expect(queries.last.family, ArticleFamily.uniforme);
    expect(queries.last.classId, isNull);
  });

  test(
    'basculer sur Classe retire le type d\'article, et relit la liste',
    () async {
      await start();
      await cubit.familySelected(ArticleFamily.uniforme);
      await cubit.modeChanged(SalesFilterMode.classroom);
      expect(cubit.state.family, isNull);
      expect(queries.last.family, isNull);
      expect(queries.last.classId, isNull);

      await cubit.classSelected('c-6a');
      expect(queries.last.classId, 'c-6a');
      expect(queries.last.family, isNull);
      expect(cubit.state.classLabel, '6e A');
    },
  );

  test('basculer sans critère posé ne relit rien', () async {
    await start();
    await cubit.modeChanged(SalesFilterMode.classroom);
    expect(queries, hasLength(1));
  });

  test('changer de page garde la page affichée pendant la lecture', () async {
    await start();
    final next = Completer<Either<Failure, BoutiqueSalesPage>>();
    when(() => getSales(any())).thenAnswer((_) => next.future);

    final pending = cubit.pageChanged(1);
    expect(cubit.state.status, SalesStatus.loading);
    expect(cubit.state.page!.page, 0);

    next.complete(Right(salesPageOf(total: 25, page: 1)));
    await pending;
    expect(cubit.state.page!.page, 1);
  });

  test('un autre filtre retire l\'ancienne page : squelette', () async {
    await start();
    final next = Completer<Either<Failure, BoutiqueSalesPage>>();
    when(() => getSales(any())).thenAnswer((_) => next.future);

    final pending = cubit.familySelected(ArticleFamily.actes);
    expect(cubit.state.page, isNull);
    next.complete(Right(salesPageOf()));
    await pending;
  });

  test('une autre période repart de la page 1, filtre gardé', () async {
    await start();
    await cubit.familySelected(ArticleFamily.uniforme);
    await cubit.pageChanged(2);
    await cubit.windowChanged(sevenDays);
    expect(queries.last.window, sevenDays);
    expect(queries.last.page, 0);
    expect(queries.last.family, ArticleFamily.uniforme);
  });

  test('une réponse dépassée par un geste posé depuis est jetée', () async {
    await start();
    final slow = Completer<Either<Failure, BoutiqueSalesPage>>();
    when(() => getSales(any())).thenAnswer((_) => slow.future);
    final first = cubit.familySelected(ArticleFamily.uniforme);

    when(
      () => getSales(any()),
    ).thenAnswer((_) async => Right(salesPageOf(total: 1)));
    await cubit.familySelected(ArticleFamily.actes);

    slow.complete(Right(salesPageOf(total: 99)));
    await first;
    expect(cubit.state.page!.totalElements, 1);
    expect(cubit.state.family, ArticleFamily.actes);
  });

  test('réessayer rejoue la même page et le même filtre', () async {
    await start();
    await cubit.familySelected(ArticleFamily.uniforme);
    await cubit.pageChanged(1);
    when(
      () => getSales(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));
    await cubit.pageChanged(2);
    expect(cubit.state.status, SalesStatus.failure);

    when(() => getSales(any())).thenAnswer((i) async {
      queries.add(i.positionalArguments.first as SalesQuery);
      return Right(salesPageOf(total: 25, page: 2));
    });
    await cubit.retry();
    expect(queries.last.page, 2);
    expect(queries.last.family, ArticleFamily.uniforme);
  });
}
