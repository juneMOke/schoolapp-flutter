import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_pull_outcome.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_pull_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_disciplinary_pull_usecase.dart';

class MockDisciplinaryPullRepository extends Mock
    implements DisciplinaryPullRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockDisciplinaryPullRepository repository;
  late MockConnectivityService connectivity;
  late SyncDisciplinaryPullUseCase useCase;

  const outcome = DisciplinaryPullOutcome(
    upserted: 1,
    notModified: false,
    bootstrapComplete: false,
    syncedAt: 10000,
  );

  setUp(() {
    repository = MockDisciplinaryPullRepository();
    connectivity = MockConnectivityService();
    useCase = SyncDisciplinaryPullUseCase(repository, connectivity);
  });

  test('en ligne -> délègue au repository', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(
      () => repository.syncDisciplinaryCases(),
    ).thenAnswer((_) async => const Right(outcome));

    final result = await useCase();

    expect(result, const Right(outcome));
    verify(() => repository.syncDisciplinaryCases()).called(1);
  });

  test(
    'hors-ligne -> ne tape pas le repository et renvoie NetworkFailure',
    () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

      final result = await useCase();

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
      verifyNever(() => repository.syncDisciplinaryCases());
    },
  );
}
