import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/boutique_catalog.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/pricing_mode.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_beneficiaries_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_cubit.dart';

import '../dashboard_fixtures.dart';

class _MockBeneficiaries extends Mock
    implements GetBoutiqueBeneficiariesUseCase {}

class _MockCatalog extends Mock implements GetBoutiqueCatalogUseCase {}

void main() {
  late _MockBeneficiaries getBeneficiaries;
  late _MockCatalog getCatalog;
  final queries = <BeneficiariesQuery>[];

  setUpAll(
    () => registerFallbackValue(
      BeneficiariesQuery(academicYearId: '', window: sevenDays),
    ),
  );

  setUp(() {
    queries.clear();
    getBeneficiaries = _MockBeneficiaries();
    getCatalog = _MockCatalog();
    when(() => getBeneficiaries(any())).thenAnswer((i) async {
      queries.add(i.positionalArguments.first as BeneficiariesQuery);
      return Right(beneficiariesOf());
    });
    when(() => getCatalog(any())).thenAnswer(
      (_) async => const Right(
        BoutiqueCatalog(
          withheld: false,
          articles: [
            BoutiqueArticle(
              id: 'a-jdc',
              academicYearId: 'ay-1',
              code: 'JDC',
              label: 'Journal de classe',
              family: ArticleFamily.fournitures,
              pricingMode: PricingMode.prixUnique,
              currency: 'USD',
              unitPriceInCents: 500,
            ),
          ],
        ),
      ),
    );
  });

  BoutiqueBeneficiariesCubit build() => BoutiqueBeneficiariesCubit(
    getBeneficiaries: getBeneficiaries,
    getCatalog: getCatalog,
    debounce: Duration.zero,
  );

  test(
    'au départ : la page sans filtre, et tout le catalogue au menu',
    () async {
      final cubit = build();
      await cubit.start(academicYearId: 'ay-1', window: sevenDays);
      expect(cubit.state.status, BeneficiariesStatus.ready);
      expect(queries.single.isUnfiltered, isTrue);
      expect(cubit.state.articleOptions.single.label, 'Journal de classe');
      await cubit.close();
    },
  );

  test('les filtres survivent au changement de période', () async {
    final cubit = build();
    await cubit.start(academicYearId: 'ay-1', window: sevenDays);
    await cubit.articleSelected('a-polo', label: 'Polo Lacoste');
    await cubit.classSelected('c-6a');
    final thirty = DashboardWindow(
      from: DateTime(2026, 9, 22),
      to: DateTime(2026, 10, 21),
    );
    await cubit.windowChanged(thirty);
    expect(queries.last.articleId, 'a-polo');
    expect(queries.last.classId, 'c-6a');
    expect(queries.last.window, thirty);
    // Un article retiré du catalogue, posé par le palmarès, se nomme quand même.
    expect(cubit.state.articleLabel, 'Polo Lacoste');
    expect(cubit.state.classLabel, '6e A');
    await cubit.close();
  });

  test('la recherche attend la fin de la frappe', () async {
    final cubit = BoutiqueBeneficiariesCubit(
      getBeneficiaries: getBeneficiaries,
      getCatalog: getCatalog,
      debounce: const Duration(milliseconds: 20),
    );
    await cubit.start(academicYearId: 'ay-1', window: sevenDays);
    cubit
      ..searchChanged('k')
      ..searchChanged('ka')
      ..searchChanged('kab');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(queries.map((q) => q.search), ['', 'kab']);
    await cubit.close();
  });

  test('réinitialiser vide les trois filtres', () async {
    final cubit = build();
    await cubit.start(academicYearId: 'ay-1', window: sevenDays);
    await cubit.articleSelected('a-jdc');
    cubit.searchChanged('kab');
    await cubit.resetFilters();
    expect(cubit.state.hasFilters, isFalse);
    expect(queries.last.isUnfiltered, isTrue);
    await cubit.close();
  });

  test('la page suivante s\'ajoute ; son échec ne vide rien', () async {
    when(() => getBeneficiaries(any())).thenAnswer((i) async {
      final q = i.positionalArguments.first as BeneficiariesQuery;
      return Right(beneficiariesOf(count: 2, total: 4, page: q.page, size: 2));
    });
    final cubit = build();
    await cubit.start(academicYearId: 'ay-1', window: sevenDays);
    await cubit.loadMore();
    expect(cubit.state.page!.items, hasLength(4));
    expect(cubit.state.page!.hasMore, isFalse);

    when(
      () => getBeneficiaries(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('x')));
    await cubit.loadMore();
    expect(cubit.state.page!.items, hasLength(4));
    await cubit.close();
  });

  test('une réponse dépassée par un filtre posé depuis est jetée', () async {
    final slow = Completer<Either<Failure, BoutiqueBeneficiariesPage>>();
    var calls = 0;
    when(() => getBeneficiaries(any())).thenAnswer((_) {
      calls++;
      return calls == 1
          ? slow.future
          : Future.value(Right(beneficiariesOf(count: 1, total: 1)));
    });
    final cubit = build();
    unawaited(cubit.start(academicYearId: 'ay-1', window: sevenDays));
    await Future<void>.delayed(Duration.zero);
    await cubit.classSelected('c-6a');
    slow.complete(Right(beneficiariesOf(count: 5, total: 5)));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.page!.items, hasLength(1));
    await cubit.close();
  });

  test(
    'la classe choisie reste nommée quand une période ne la porte plus',
    () async {
      final cubit = build();
      await cubit.start(academicYearId: 'ay-1', window: sevenDays);
      await cubit.classSelected('c-6a');
      when(() => getBeneficiaries(any())).thenAnswer(
        (_) async => const Right(
          BoutiqueBeneficiariesPage(totalElements: 0, page: 0, size: 100),
        ),
      );
      await cubit.windowChanged(
        DashboardWindow(
          from: DateTime(2026, 10, 21),
          to: DateTime(2026, 10, 21),
        ),
      );
      expect(cubit.state.classId, 'c-6a');
      expect(cubit.state.classLabel, '6e A');
      await cubit.resetFilters();
      expect(cubit.state.classLabel, isNull);
      await cubit.close();
    },
  );

  test('réessayer rejoue la même question, filtres compris', () async {
    final cubit = build();
    await cubit.start(academicYearId: 'ay-1', window: sevenDays);
    await cubit.classSelected('c-6a');
    await cubit.retry();
    expect(queries.last.classId, 'c-6a');
    await cubit.close();
  });
}
