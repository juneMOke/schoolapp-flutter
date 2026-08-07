import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/classroom_sync_outcome.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/assign_enrollment_to_classroom_usecase.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

class MockClassroomOfflineRepository extends Mock
    implements ClassroomOfflineRepository {}

class FakeClassroomMember extends Fake implements ClassroomMember {}

const tClassroomId = 'classroom-2';
const tEnrollmentId = 'enrollment-1';
const tAcademicYearId = 'year-1';

const tCreatedMember = ClassroomMember(
  id: 'member-created',
  studentId: 'student-1',
  classroomId: tClassroomId,
  academicYearId: tAcademicYearId,
  studentFirstName: 'Jane',
  studentLastName: 'Doe',
  studentMiddleName: 'K',
  studentGender: ClassroomMemberGender.female,
);

const tSyncOutcome = ClassroomSyncOutcome(
  classroomsUpserted: 1,
  membersUpserted: 1,
  notModified: false,
  syncedAt: 1720000000000,
);

void main() {
  late MockClassroomRepository online;
  late MockClassroomOfflineRepository offline;
  late AssignEnrollmentToClassroomUseCase useCase;

  setUpAll(() => registerFallbackValue(FakeClassroomMember()));

  setUp(() {
    online = MockClassroomRepository();
    offline = MockClassroomOfflineRepository();
    useCase = AssignEnrollmentToClassroomUseCase(
      onlineRepository: online,
      offlineRepository: offline,
    );
  });

  void stubOnline(Either<Failure, ClassroomMember> result) {
    when(
      () => online.assignEnrollmentToClassroom(
        classroomId: tClassroomId,
        enrollmentId: tEnrollmentId,
      ),
    ).thenAnswer((_) async => result);
  }

  void stubMirror({
    Either<Failure, void> upsert = const Right(null),
    Either<Failure, ClassroomSyncOutcome> repull = const Right(tSyncOutcome),
  }) {
    when(() => offline.upsertAssignedMember(any())).thenAnswer((_) async {
      return upsert;
    });
    when(
      () => offline.syncClassrooms(academicYearId: tAcademicYearId),
    ).thenAnswer((_) async => repull);
  }

  Future<Either<Failure, bool>> call() => useCase(
    classroomId: tClassroomId,
    enrollmentId: tEnrollmentId,
    academicYearId: tAcademicYearId,
  );

  test('affecte, intègre le membre créé au miroir, puis re-pull', () async {
    stubOnline(const Right(tCreatedMember));
    stubMirror();

    final result = await call();

    expect(result, const Right<Failure, bool>(true));
    // Le membre canonique du 201 part tel quel dans le miroir : sans ça,
    // l'élève resterait dans « non répartis » jusqu'au prochain pull.
    verify(() => offline.upsertAssignedMember(tCreatedMember)).called(1);
    verify(
      () => offline.syncClassrooms(academicYearId: tAcademicYearId),
    ).called(1);
  });

  test('échec serveur → Left, aucune écriture locale', () async {
    stubOnline(const Left(ValidationFailure('Invalid request data')));
    stubMirror();

    final result = await call();

    expect(
      result,
      const Left<Failure, bool>(ValidationFailure('Invalid request data')),
    );
    verifyNever(() => offline.upsertAssignedMember(any()));
    verifyNever(
      () =>
          offline.syncClassrooms(academicYearId: any(named: 'academicYearId')),
    );
  });

  test(
    'écriture miroir KO → succès partiel Right(false), pas un échec',
    () async {
      stubOnline(const Right(tCreatedMember));
      stubMirror(upsert: const Left(StorageFailure('disk full')));

      expect(await call(), const Right<Failure, bool>(false));
    },
  );

  test('re-pull KO → succès partiel Right(false), pas un échec', () async {
    stubOnline(const Right(tCreatedMember));
    stubMirror(repull: const Left(NetworkFailure('offline')));

    expect(await call(), const Right<Failure, bool>(false));
  });

  test(
    're-pull tenté même si l\'intégration miroir a échoué (rattrapage)',
    () async {
      stubOnline(const Right(tCreatedMember));
      stubMirror(upsert: const Left(StorageFailure('disk full')));

      await call();

      verify(
        () => offline.syncClassrooms(academicYearId: tAcademicYearId),
      ).called(1);
    },
  );
}
