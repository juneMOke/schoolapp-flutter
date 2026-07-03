import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/classroom_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_my_courses_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/course_state.dart';

class MockGetMyCoursesUseCase extends Mock implements GetMyCoursesUseCase {}

const tCourse = CourseSummary(
  classroom: ClassroomSummary(
    id: 'c1',
    schoolLevelId: 'lvl-1',
    name: '6ème A',
    capacity: 40,
    totalCount: 32,
    femaleCount: 18,
    maleCount: 14,
  ),
  courses: [
    CourseRef(id: 'crs-1', label: 'Algèbre'),
    CourseRef(id: 'crs-2', label: 'Français'),
  ],
);

void main() {
  late MockGetMyCoursesUseCase mockGetMyCoursesUseCase;

  setUp(() {
    mockGetMyCoursesUseCase = MockGetMyCoursesUseCase();
  });

  CourseBloc buildBloc() =>
      CourseBloc(getMyCoursesUseCase: mockGetMyCoursesUseCase);

  group('MyCoursesRequested', () {
    blocTest<CourseBloc, CourseState>(
      'emits loading then success with fetched courses',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Right([tCourse]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.success,
          courses: [tCourse],
          errorType: CourseErrorType.none,
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'emits loading then success with empty list',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.success,
          errorType: CourseErrorType.none,
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'maps NotFoundFailure to notFound error type',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.failure,
          errorType: CourseErrorType.notFound,
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'maps UnauthorizedFailure (403) to forbidden error type',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Left(UnauthorizedFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.failure,
          errorType: CourseErrorType.forbidden,
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'maps NetworkFailure to network error type',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.failure,
          errorType: CourseErrorType.network,
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'maps InvalidCredentialsFailure (401) to invalidCredentials error type',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Left(InvalidCredentialsFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.failure,
          errorType: CourseErrorType.invalidCredentials,
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'maps ValidationFailure (400/422) to validation error type',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Left(ValidationFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.failure,
          errorType: CourseErrorType.validation,
        ),
      ],
    );

    blocTest<CourseBloc, CourseState>(
      'maps ServerFailure (5xx) to server error type',
      setUp: () {
        when(
          () => mockGetMyCoursesUseCase(),
        ).thenAnswer((_) async => const Left(ServerFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MyCoursesRequested()),
      expect: () => const [
        CourseState(
          status: CourseStatus.loading,
          errorType: CourseErrorType.none,
        ),
        CourseState(
          status: CourseStatus.failure,
          errorType: CourseErrorType.server,
        ),
      ],
    );
  });
}
