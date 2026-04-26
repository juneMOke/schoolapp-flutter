import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';

class MockGetClassroomsUseCase extends Mock implements GetClassroomsUseCase {}

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
  late MockGetClassroomsUseCase mockGetClassroomsUseCase;

  setUp(() {
    mockGetClassroomsUseCase = MockGetClassroomsUseCase();
  });

  ClassroomBloc buildBloc() =>
      ClassroomBloc(getClassroomsUseCase: mockGetClassroomsUseCase);

  group('ClassroomRequested', () {
    blocTest<ClassroomBloc, ClassroomState>(
      'emits [loading, success] when classrooms are loaded',
      setUp: () {
        when(
          () => mockGetClassroomsUseCase(
            schoolLevelGroupId: tSchoolLevelGroupId,
            schoolLevelId: tSchoolLevelId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right([tClassroom]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomRequested(
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomState(status: ClassroomStatus.loading),
        ClassroomState(
          status: ClassroomStatus.success,
          classrooms: [tClassroom],
        ),
      ],
    );

    blocTest<ClassroomBloc, ClassroomState>(
      'emits failure with notFound error type on NotFoundFailure',
      setUp: () {
        when(
          () => mockGetClassroomsUseCase(
            schoolLevelGroupId: tSchoolLevelGroupId,
            schoolLevelId: tSchoolLevelId,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Left(NotFoundFailure('Not found')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomRequested(
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => const [
        ClassroomState(status: ClassroomStatus.loading),
        ClassroomState(
          status: ClassroomStatus.failure,
          errorType: ClassroomErrorType.notFound,
        ),
      ],
    );
  });

  group('ClassroomResetRequested', () {
    blocTest<ClassroomBloc, ClassroomState>(
      'emits initial state when reset is requested',
      build: buildBloc,
      seed: () => const ClassroomState(
        status: ClassroomStatus.success,
        classrooms: [tClassroom],
      ),
      act: (bloc) => bloc.add(const ClassroomResetRequested()),
      expect: () => const [ClassroomState()],
    );
  });
}
