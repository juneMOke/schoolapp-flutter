import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_periodes_scolaires_usecase.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_bloc.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_event.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/periodes_scolaires_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

class MockGetPeriodesScolairesUseCase extends Mock
    implements GetPeriodesScolairesUseCase {}

const _tPeriodes = [
  PeriodeScolaire(
    id: 'p1',
    ordre: 1,
    decoupage: Decoupage.trimestre,
    statut: StatutPeriode.ouverte,
  ),
];

void main() {
  late MockGetPeriodesScolairesUseCase useCase;

  setUp(() => useCase = MockGetPeriodesScolairesUseCase());

  PeriodesScolairesBloc build() =>
      PeriodesScolairesBloc(getPeriodesScolaires: useCase);

  const event = PeriodesScolairesRequested(classroomId: 'cls');

  blocTest<PeriodesScolairesBloc, PeriodesScolairesState>(
    'liste non vide → loading puis success',
    build: () {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Right(_tPeriodes));
      return build();
    },
    act: (bloc) => bloc.add(event),
    expect: () => const [
      PeriodesScolairesState(status: PeriodesScolairesStatus.loading),
      PeriodesScolairesState(
        status: PeriodesScolairesStatus.success,
        periodes: _tPeriodes,
      ),
    ],
  );

  blocTest<PeriodesScolairesBloc, PeriodesScolairesState>(
    'liste vide → empty',
    build: () {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Right(<PeriodeScolaire>[]));
      return build();
    },
    act: (bloc) => bloc.add(event),
    expect: () => const [
      PeriodesScolairesState(status: PeriodesScolairesStatus.loading),
      PeriodesScolairesState(status: PeriodesScolairesStatus.empty),
    ],
  );

  blocTest<PeriodesScolairesBloc, PeriodesScolairesState>(
    'échec réseau → failure + errorType.network',
    build: () {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('x')));
      return build();
    },
    act: (bloc) => bloc.add(event),
    expect: () => const [
      PeriodesScolairesState(status: PeriodesScolairesStatus.loading),
      PeriodesScolairesState(
        status: PeriodesScolairesStatus.failure,
        errorType: ResultatsErrorType.network,
      ),
    ],
  );

  blocTest<PeriodesScolairesBloc, PeriodesScolairesState>(
    '403 → forbidden (convention projet)',
    build: () {
      when(
        () => useCase(any()),
      ).thenAnswer((_) async => const Left(UnauthorizedFailure('x')));
      return build();
    },
    act: (bloc) => bloc.add(event),
    expect: () => const [
      PeriodesScolairesState(status: PeriodesScolairesStatus.loading),
      PeriodesScolairesState(
        status: PeriodesScolairesStatus.failure,
        errorType: ResultatsErrorType.forbidden,
      ),
    ],
  );
}
