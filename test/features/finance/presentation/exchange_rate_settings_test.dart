import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_exchange_rates_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/save_exchange_rate_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rate_settings_cubit.dart';

/// Le paramétrage du taux, côté direction.
///
/// **C'est la porte d'entrée de tout le chantier bi-devise** : rien d'autre
/// n'écrit dans le référentiel local, et sans taux, la bascule du guichet
/// n'apparaît jamais.
class _FakeRepo implements FinanceOfflineRepository {
  final List<ExchangeRate> stored = [];
  Failure? failWith;

  @override
  Future<Either<Failure, List<ExchangeRate>>> getExchangeRates() async =>
      Right(List<ExchangeRate>.from(stored));

  @override
  Future<Either<Failure, Unit>> saveExchangeRate({
    required String base,
    required String quote,
    required int rateMicros,
    required DateTime effectiveFrom,
    int? divergenceBandBp,
  }) async {
    if (failWith case final failure?) return Left(failure);
    stored.add(
      ExchangeRate(
        base: base,
        quote: quote,
        rateMicros: rateMicros,
        effectiveFrom: effectiveFrom,
        divergenceBandBp: divergenceBandBp,
      ),
    );
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('hors périmètre');
}

void main() {
  late _FakeRepo repo;
  late ExchangeRateSettingsCubit cubit;
  var now = DateTime.utc(2026, 9, 1, 8);

  setUp(() {
    repo = _FakeRepo();
    cubit = ExchangeRateSettingsCubit(
      getRates: GetExchangeRatesUseCase(repo),
      saveRate: SaveExchangeRateUseCase(repo),
      now: () => now,
    );
  });

  tearDown(() async => cubit.close());

  test('une école neuve n’a aucun taux, et le dit', () async {
    await cubit.load();

    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.rates, isEmpty);
    expect(cubit.state.currentFor(base: 'USD', quote: 'CDF'), isNull);
  });

  test('enregistrer un taux le rend lisible immédiatement', () async {
    await cubit.load();
    await cubit.save(base: 'USD', quote: 'CDF', rateMicros: 2850000000);

    expect(cubit.state.status, ExchangeRateSettingsStatus.saved);
    expect(
      cubit.state.currentFor(base: 'USD', quote: 'CDF')?.rateMicros,
      2850000000,
    );
  });

  test('un second enregistrement ajoute un palier, il n’écrase pas', () async {
    // L'école qui change de taux à midi en pose un second : le versement du
    // matin garde le sien, et un ticket réimprimé six mois plus tard ne bouge
    // pas.
    await cubit.load();
    await cubit.save(base: 'USD', quote: 'CDF', rateMicros: 2850000000);
    now = DateTime.utc(2026, 9, 1, 12);
    await cubit.save(base: 'USD', quote: 'CDF', rateMicros: 2900000000);

    expect(cubit.state.rates, hasLength(2));
    // C'est le plus récent qui vaut aujourd'hui…
    expect(
      cubit.state.currentFor(base: 'USD', quote: 'CDF')?.rateMicros,
      2900000000,
    );
    // …et celui du matin reste résolvable pour un versement du matin.
    expect(
      ExchangeRates.at(
        cubit.state.rates,
        base: 'USD',
        quote: 'CDF',
        moment: DateTime.utc(2026, 9, 1, 9),
      )?.rateMicros,
      2850000000,
    );
  });

  test('les deux sens se posent séparément', () async {
    // L'inverse n'est jamais dérivé : 1 ÷ 2 850 tombe sur 0,000350877…, et
    // l'arrondi ferait diverger les deux sens d'un même taux.
    await cubit.load();
    await cubit.save(base: 'USD', quote: 'CDF', rateMicros: 2850000000);

    expect(cubit.state.currentFor(base: 'CDF', quote: 'USD'), isNull);
  });

  test('un échec d’écriture se dit, et ne perd pas la série', () async {
    await cubit.load();
    await cubit.save(base: 'USD', quote: 'CDF', rateMicros: 2850000000);
    repo.failWith = const ValidationFailure('Taux de guichet invalide.');

    await cubit.save(base: 'USD', quote: 'CDF', rateMicros: 0);

    expect(cubit.state.status, ExchangeRateSettingsStatus.failed);
    expect(cubit.state.errorMessage, 'Taux de guichet invalide.');
    expect(cubit.state.rates, hasLength(1));
  });
}
