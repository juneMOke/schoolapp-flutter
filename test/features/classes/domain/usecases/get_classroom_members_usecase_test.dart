import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_members_usecase.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

const tClassroomId = 'classroom-1';
const tAcademicYearId = 'year-1';

const tClassroomMember = ClassroomMember(
  id: 'member-1',
  studentId: 'student-1',
  classroomId: tClassroomId,
  academicYearId: tAcademicYearId,
  studentFirstName: 'John',
  studentLastName: 'Doe',
  studentMiddleName: 'K',
  studentGender: ClassroomMemberGender.male,
);

void main() {
  late MockClassroomRepository mockRepository;
  late GetClassroomMembersUseCase useCase;

  setUp(() {
    mockRepository = MockClassroomRepository();
    useCase = GetClassroomMembersUseCase(mockRepository);
  });

  test('delegates to repository and returns Right on success', () async {
    when(
      () => mockRepository.getClassroomMembers(
        classroomId: tClassroomId,
        academicYearId: tAcademicYearId,
      ),
    ).thenAnswer((_) async => const Right([tClassroomMember]));

    final result = await useCase(
      classroomId: tClassroomId,
      academicYearId: tAcademicYearId,
    );

    result.fold(
      (_) => fail('Expected Right but got Left'),
      (members) => expect(members, const [tClassroomMember]),
    );
    verify(
      () => mockRepository.getClassroomMembers(
        classroomId: tClassroomId,
        academicYearId: tAcademicYearId,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left on failure', () async {
    const failure = NetworkFailure('Network error occurred');
    when(
      () => mockRepository.getClassroomMembers(
        classroomId: tClassroomId,
        academicYearId: tAcademicYearId,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      classroomId: tClassroomId,
      academicYearId: tAcademicYearId,
    );

    expect(result, const Left<Failure, List<ClassroomMember>>(failure));
  });
}
