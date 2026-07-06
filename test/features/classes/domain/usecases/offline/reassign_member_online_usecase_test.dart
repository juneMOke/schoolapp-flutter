import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/reassign_member_online_usecase.dart';

class MockOnlineRepo extends Mock implements ClassroomRepository {}

class MockOfflineRepo extends Mock implements ClassroomOfflineRepository {}

void main() {
  late MockOnlineRepo online;
  late MockOfflineRepo offline;
  late ReassignMemberOnlineUseCase usecase;

  const memberId = 'member-1';
  const targetId = 'class-b';
  const yearId = 'year-1';

  setUp(() {
    online = MockOnlineRepo();
    offline = MockOfflineRepo();
    usecase = ReassignMemberOnlineUseCase(
      onlineRepository: online,
      offlineRepository: offline,
    );
  });

  const outcome = ClassroomSyncOutcome(
    classroomsUpserted: 2,
    membersUpserted: 1,
    notModified: false,
    syncedAt: 100,
  );

  test(
    'succès online → déclenche le re-pull (Option A, zéro outbox)',
    () async {
      when(
        () => online.reassignClassroomMember(
          classroomMemberId: any(named: 'classroomMemberId'),
          targetClassroomId: any(named: 'targetClassroomId'),
        ),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => offline.syncClassrooms(
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer((_) async => const Right(outcome));

      final result = await usecase(
        classroomMemberId: memberId,
        targetClassroomId: targetId,
        academicYearId: yearId,
      );

      expect(result, const Right<Failure, bool>(true));
      verify(() => offline.syncClassrooms(academicYearId: yearId)).called(1);
    },
  );

  test('échec online → PAS de re-pull, propage le Failure', () async {
    when(
      () => online.reassignClassroomMember(
        classroomMemberId: any(named: 'classroomMemberId'),
        targetClassroomId: any(named: 'targetClassroomId'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await usecase(
      classroomMemberId: memberId,
      targetClassroomId: targetId,
      academicYearId: yearId,
    );

    expect(result, isA<Left<Failure, bool>>());
    verifyNever(
      () =>
          offline.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    );
  });

  test('succès online mais re-pull KO → Right(false)', () async {
    when(
      () => online.reassignClassroomMember(
        classroomMemberId: any(named: 'classroomMemberId'),
        targetClassroomId: any(named: 'targetClassroomId'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      () =>
          offline.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await usecase(
      classroomMemberId: memberId,
      targetClassroomId: targetId,
      academicYearId: yearId,
    );

    expect(result, const Right<Failure, bool>(false));
  });
}
