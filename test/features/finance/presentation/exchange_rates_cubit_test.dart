import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_exchange_rates_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';

class _MockGetRates extends Mock implements GetExchangeRatesUseCase {}

final _rate = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2300000000,
  effectiveFrom: DateTime.utc(2026, 9, 1),
);

/// La série de taux, à l'écran du guichet.
///
/// ⚠️ **Ce que ces tests tiennent est une course, pas un calcul.** La page se
/// monte, lit un cache encore froid, et le pull des taux part au même instant
/// depuis le `FeatureScope`. Sans réveil, la série reste vide pour toute la
/// durée de l'écran : le caissier lit « aucun taux paramétré » alors que le
/// bundle vient d'arriver — et il faut sortir de la feature et y revenir pour
/// que la bascule apparaisse.
void main() {
  late _MockGetRates getRates;
  late PullCompletionBus bus;

  setUp(() {
    getRates = _MockGetRates();
    bus = PullCompletionBus();
  });

  tearDown(() => bus.dispose());

  test('au montage, la série lue est celle du cache', () async {
    when(getRates.call).thenAnswer((_) async => Right([_rate]));

    final cubit = ExchangeRatesCubit(getRates, pullBus: bus);
    await cubit.load();

    expect(cubit.state.rates, [_rate]);
    expect(cubit.state.loaded, isTrue);
    await cubit.close();
  });

  test(
    'le pull des taux RÉVEILLE l’écran : le cache froid ne le reste pas',
    () async {
      // Premier appel : la table est encore vide (le pull n'a pas fini).
      // Second : il a écrit.
      var appels = 0;
      when(getRates.call).thenAnswer((_) async {
        appels++;
        return appels == 1
            ? const Right<Failure, List<ExchangeRate>>(<ExchangeRate>[])
            : Right<Failure, List<ExchangeRate>>([_rate]);
      });

      final cubit = ExchangeRatesCubit(getRates, pullBus: bus);
      await cubit.load();
      expect(cubit.state.rates, isEmpty);

      bus.notifyUpdated({FinancePullRepositoryImpl.exchangeRatesResource});
      await Future<void>.delayed(Duration.zero);

      expect(
        cubit.state.rates,
        [_rate],
        reason:
            'sans ce réveil, il faut sortir de la feature et y revenir pour '
            'voir la bascule — l’impression tenace que « le pull ne marche pas »',
      );
      await cubit.close();
    },
  );

  test('un pull d’une AUTRE ressource ne relit rien', () async {
    when(getRates.call).thenAnswer((_) async => Right([_rate]));

    final cubit = ExchangeRatesCubit(getRates, pullBus: bus);
    await cubit.load();

    bus.notifyUpdated({FinancePullRepositoryImpl.chargesResource});
    await Future<void>.delayed(Duration.zero);

    verify(getRates.call).called(1);
    await cubit.close();
  });

  test('sans bus, l’écran reste fonctionnel en lecture locale', () async {
    when(getRates.call).thenAnswer((_) async => Right([_rate]));

    final cubit = ExchangeRatesCubit(getRates);
    await cubit.load();

    expect(cubit.state.rates, [_rate]);
    await cubit.close();
  });

  test('fermé, il ne se réveille plus', () async {
    when(getRates.call).thenAnswer((_) async => Right([_rate]));

    final cubit = ExchangeRatesCubit(getRates, pullBus: bus);
    await cubit.load();
    await cubit.close();

    bus.notifyUpdated({FinancePullRepositoryImpl.exchangeRatesResource});
    await Future<void>.delayed(Duration.zero);

    verify(getRates.call).called(1);
  });

  test(
    'une lecture en échec laisse l’écran d’avant, sans message d’erreur',
    () async {
      when(
        getRates.call,
      ).thenAnswer((_) async => const Left(StorageFailure('base illisible')));

      final cubit = ExchangeRatesCubit(getRates, pullBus: bus);
      await cubit.load();

      expect(cubit.state.rates, isEmpty);
      expect(cubit.state.loaded, isTrue);
      await cubit.close();
    },
  );
}
