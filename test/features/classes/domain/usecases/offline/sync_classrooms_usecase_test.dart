import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classrooms_usecase.dart';

class MockClassroomOfflineRepository extends Mock
    implements ClassroomOfflineRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockClassroomOfflineRepository repository;
  late MockConnectivityService connectivity;
  late SyncClassroomsUseCase useCase;

  const outcome = ClassroomSyncOutcome(
    classroomsUpserted: 1,
    membersUpserted: 2,
    notModified: false,
    syncedAt: 10000,
  );

  setUp(() {
    repository = MockClassroomOfflineRepository();
    connectivity = MockConnectivityService();
    useCase = SyncClassroomsUseCase(repository, connectivity);
  });

  test('en ligne -> délègue au repository', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    when(
      () => repository.syncClassrooms(academicYearId: 'ay-1'),
    ).thenAnswer((_) async => const Right(outcome));

    final result = await useCase(academicYearId: 'ay-1');

    expect(result, const Right(outcome));
    verify(() => repository.syncClassrooms(academicYearId: 'ay-1')).called(1);
  });

  test(
    'hors-ligne -> ne tape pas le repository et renvoie NetworkFailure',
    () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

      final result = await useCase(academicYearId: 'ay-1');

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
      verifyNever(
        () => repository.syncClassrooms(
          academicYearId: any(named: 'academicYearId'),
        ),
      );
    },
  );
}
