import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_registers_cubit.dart';

import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements CashRegistersRepository {}

void main() {
  late _MockRepository repo;
  late CashRegistersCubit cubit;

  setUpAll(() => registerFallbackValue(TreasuryCurrency.usd));

  setUp(() {
    repo = _MockRepository();
    cubit = CashRegistersCubit(repo);
  });

  tearDown(() => cubit.close());

  test('chargement : les caisses dans l ordre du serveur', () async {
    when(() => repo.list()).thenAnswer((_) async => Right([usdConfig]));
    await cubit.load();
    expect(cubit.state.status, CashRegistersStatus.ready);
    expect(cubit.state.registers, [usdConfig]);
  });

  test('échec du chargement : l état d erreur garde son échec', () async {
    when(
      () => repo.list(),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    await cubit.load();
    expect(cubit.state.status, CashRegistersStatus.failure);
    expect(cubit.state.failure, const NetworkFailure());
  });

  test(
    'créer : la liste est RELUE au serveur, jamais recomposée ici',
    () async {
      var calls = 0;
      when(() => repo.list()).thenAnswer(
        (_) async => Right(calls++ == 0 ? [usdConfig] : [usdConfig, cdfConfig]),
      );
      when(
        () => repo.create(
          currency: any(named: 'currency'),
          name: any(named: 'name'),
          openingAmountInCents: any(named: 'openingAmountInCents'),
        ),
      ).thenAnswer((_) async => Right(cdfRegister));
      await cubit.load();

      final failure = await cubit.create(
        currency: TreasuryCurrency.cdf,
        name: null,
        openingAmountInCents: 75000000,
      );

      expect(failure, isNull);
      expect(cubit.state.registers, [usdConfig, cdfConfig]);
      verify(() => repo.list()).called(2);
    },
  );

  test('créer refusé : l échec revient à la modale, rien n est relu', () async {
    when(() => repo.list()).thenAnswer((_) async => Right([usdConfig]));
    when(
      () => repo.create(
        currency: any(named: 'currency'),
        name: any(named: 'name'),
        openingAmountInCents: any(named: 'openingAmountInCents'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        TreasuryRefusalFailure(TreasuryRefusal.currencyAlreadyHasRegister),
      ),
    );
    await cubit.load();

    final failure = await cubit.create(
      currency: TreasuryCurrency.usd,
      name: null,
      openingAmountInCents: 0,
    );

    expect(
      (failure! as TreasuryRefusalFailure).refusal,
      TreasuryRefusal.currencyAlreadyHasRegister,
    );
    verify(() => repo.list()).called(1);
  });

  test(
    'ajuster : la clé de rejeu et le montant montré partent tels quels',
    () async {
      when(() => repo.list()).thenAnswer((_) async => Right([usdConfig]));
      when(
        () => repo.adjust(
          registerId: 'reg-usd',
          id: 'uuid-1',
          shownExpectedInCents: 482000,
          newAmountInCents: 490000,
          reason: 'Recomptage',
        ),
      ).thenAnswer((_) async => Right(adjustment));
      await cubit.load();

      final result = await cubit.adjust(
        registerId: 'reg-usd',
        id: 'uuid-1',
        shownExpectedInCents: 482000,
        newAmountInCents: 490000,
        reason: 'Recomptage',
      );

      expect(result, Right(adjustment));
      verify(() => repo.list()).called(2);
    },
  );

  test('une relecture ratée après un geste ne vide pas l écran', () async {
    var calls = 0;
    when(() => repo.list()).thenAnswer(
      (_) async =>
          calls++ == 0 ? Right([usdConfig]) : const Left(NetworkFailure()),
    );
    when(
      () => repo.adjust(
        registerId: any(named: 'registerId'),
        id: any(named: 'id'),
        shownExpectedInCents: any(named: 'shownExpectedInCents'),
        newAmountInCents: any(named: 'newAmountInCents'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => Right(adjustment));
    await cubit.load();

    await cubit.adjust(
      registerId: 'reg-usd',
      id: 'uuid-1',
      shownExpectedInCents: 482000,
      newAmountInCents: 490000,
      reason: 'Recomptage',
    );

    expect(cubit.state.status, CashRegistersStatus.ready);
    expect(cubit.state.registers, [usdConfig]);
  });
}
