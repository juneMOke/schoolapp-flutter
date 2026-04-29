import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/reassign_classroom_member_usecase.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

const tClassroomId = 'classroom-1';
const tClassroomMemberId = 'member-1';
const tTargetClassroomId = 'classroom-2';

void main() {
  late MockClassroomRepository mockRepository;
  late ReassignClassroomMemberUseCase useCase;

  setUp(() {
    mockRepository = MockClassroomRepository();
    useCase = ReassignClassroomMemberUseCase(mockRepository);
  });

  test('delegates to repository and returns Right on success', () async {
    when(
      () => mockRepository.reassignClassroomMember(
        classroomId: tClassroomId,
        classroomMemberId: tClassroomMemberId,
        targetClassroomId: tTargetClassroomId,
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      classroomId: tClassroomId,
      classroomMemberId: tClassroomMemberId,
      targetClassroomId: tTargetClassroomId,
    );

    expect(result.isRight(), true);
    verify(
      () => mockRepository.reassignClassroomMember(
        classroomId: tClassroomId,
        classroomMemberId: tClassroomMemberId,
        targetClassroomId: tTargetClassroomId,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left on failure', () async {
    const failure = NotFoundFailure('Resource not found');
    when(
      () => mockRepository.reassignClassroomMember(
        classroomId: tClassroomId,
        classroomMemberId: tClassroomMemberId,
        targetClassroomId: tTargetClassroomId,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      classroomId: tClassroomId,
      classroomMemberId: tClassroomMemberId,
      targetClassroomId: tTargetClassroomId,
    );

    expect(result, const Left<Failure, void>(failure));
  });
}
