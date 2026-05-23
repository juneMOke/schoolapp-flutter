import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/classroom_repository.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classrooms_usecase.dart';

class MockClassroomRepository extends Mock implements ClassroomRepository {}

const tSchoolLevelGroupId = 'group-1';
const tSchoolLevelId = 'level-1';
const tAcademicYearId = 'year-1';

const tClassroom = Classroom(
  id: 'classroom-1',
  schoolLevelGroupId: tSchoolLevelGroupId,
  schoolLevelId: tSchoolLevelId,
  academicYearId: tAcademicYearId,
  name: 'A1',
  capacity: 40,
  teacherId: 'teacher-1',
  teacherFirstName: 'Alice',
  teacherLastName: 'Doe',
  teacherMiddleName: null,
  totalCount: 32,
  femaleCount: 16,
  maleCount: 16,
);

void main() {
  late MockClassroomRepository mockRepository;
  late GetClassroomsUseCase useCase;

  setUp(() {
    mockRepository = MockClassroomRepository();
    useCase = GetClassroomsUseCase(mockRepository);
  });

  test('delegates to repository and returns Right on success', () async {
    when(
      () => mockRepository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      ),
    ).thenAnswer((_) async => const Right([tClassroom]));

    final result = await useCase(
      schoolLevelGroupId: tSchoolLevelGroupId,
      schoolLevelId: tSchoolLevelId,
      academicYearId: tAcademicYearId,
    );

    result.fold(
      (_) => fail('Expected Right but got Left'),
      (classrooms) => expect(classrooms, const [tClassroom]),
    );
    verify(
      () => mockRepository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('delegates to repository and returns Left on failure', () async {
    const failure = NetworkFailure('Network error occurred');
    when(
      () => mockRepository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      ),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(
      schoolLevelGroupId: tSchoolLevelGroupId,
      schoolLevelId: tSchoolLevelId,
      academicYearId: tAcademicYearId,
    );

    expect(result, const Left<Failure, List<Classroom>>(failure));
  });
}
