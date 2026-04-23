import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_fee_tariffs_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_bloc.dart';

class MockGetFeeTariffsUseCase extends Mock implements GetFeeTariffsUseCase {}

const tLevelId = 'level-1';

const tTariff = FeeTariff(
  id: 'tariff-1',
  label: 'Frais de scolarité',
  amount: 150000.0,
  currency: 'XOF',
  levelId: tLevelId,
);

void main() {
  late MockGetFeeTariffsUseCase mockGetFeeTariffsUseCase;

  setUp(() {
    mockGetFeeTariffsUseCase = MockGetFeeTariffsUseCase();
  });

  FinanceBloc buildBloc() =>
      FinanceBloc(getFeeTariffsUseCase: mockGetFeeTariffsUseCase);

  group('FinanceFeeTariffsRequested', () {
    blocTest<FinanceBloc, FinanceState>(
      'emits [loading, success] when tariffs are loaded successfully',
      setUp: () {
        when(
          () => mockGetFeeTariffsUseCase(levelId: tLevelId),
        ).thenAnswer((_) async => const Right([tTariff]));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceFeeTariffsRequested(levelId: tLevelId)),
      expect: () => const [
        FinanceState(status: FinanceStatus.loading),
        FinanceState(status: FinanceStatus.success, tariffs: [tTariff]),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'emits [loading, success] avec liste vide quand aucun tarif renvoyé',
      setUp: () {
        when(
          () => mockGetFeeTariffsUseCase(levelId: tLevelId),
        ).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceFeeTariffsRequested(levelId: tLevelId)),
      expect: () => const [
        FinanceState(status: FinanceStatus.loading),
        FinanceState(status: FinanceStatus.success, tariffs: []),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'emits [loading, failure] avec message réseau sur NetworkFailure',
      setUp: () {
        when(
          () => mockGetFeeTariffsUseCase(levelId: tLevelId),
        ).thenAnswer(
          (_) async => const Left(NetworkFailure('Network error occurred')),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceFeeTariffsRequested(levelId: tLevelId)),
      expect: () => const [
        FinanceState(status: FinanceStatus.loading),
        FinanceState(
          status: FinanceStatus.failure,
          errorMessage: 'Vérifiez votre connexion internet',
        ),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'emits [loading, failure] avec message serveur sur ServerFailure',
      setUp: () {
        when(
          () => mockGetFeeTariffsUseCase(levelId: tLevelId),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('Server error occurred')),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceFeeTariffsRequested(levelId: tLevelId)),
      expect: () => const [
        FinanceState(status: FinanceStatus.loading),
        FinanceState(
          status: FinanceStatus.failure,
          errorMessage: 'Erreur serveur, réessayez plus tard',
        ),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'emits [loading, failure] avec message accès sur UnauthorizedFailure',
      setUp: () {
        when(
          () => mockGetFeeTariffsUseCase(levelId: tLevelId),
        ).thenAnswer(
          (_) async => const Left(UnauthorizedFailure('Access forbidden')),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceFeeTariffsRequested(levelId: tLevelId)),
      expect: () => const [
        FinanceState(status: FinanceStatus.loading),
        FinanceState(
          status: FinanceStatus.failure,
          errorMessage: 'Accès non autorisé',
        ),
      ],
    );

    blocTest<FinanceBloc, FinanceState>(
      'emits [loading, failure] avec message identifiants sur InvalidCredentialsFailure',
      setUp: () {
        when(
          () => mockGetFeeTariffsUseCase(levelId: tLevelId),
        ).thenAnswer(
          (_) async =>
              const Left(InvalidCredentialsFailure('Invalid credentials')),
        );
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const FinanceFeeTariffsRequested(levelId: tLevelId)),
      expect: () => const [
        FinanceState(status: FinanceStatus.loading),
        FinanceState(
          status: FinanceStatus.failure,
          errorMessage: 'Identifiants incorrects',
        ),
      ],
    );
  });
}
