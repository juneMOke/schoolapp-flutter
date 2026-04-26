import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/data/datasources/classroom_remote_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_model.dart';
import 'package:school_app_flutter/features/classes/data/repositories/classroom_repository_impl.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';

class MockClassroomRemoteDataSource extends Mock
    implements ClassroomRemoteDataSource {}

const tRequiredAuth = <String, dynamic>{'requiresAuth': true};
const tSchoolLevelGroupId = 'group-1';
const tSchoolLevelId = 'level-1';
const tAcademicYearId = 'year-1';

const tClassroomModel = ClassroomModel(
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
  late MockClassroomRemoteDataSource mockRemoteDataSource;
  late ClassroomRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockClassroomRemoteDataSource();
    repository = ClassroomRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      requiredAuth: tRequiredAuth,
    );
  });

  group('getClassroomsByLevelAndAcademicYear', () {
    test('returns Right(List<Classroom>) when datasource succeeds', () async {
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenAnswer((_) async => const [tClassroomModel]);

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (classrooms) => expect(classrooms, const [tClassroom]),
      );
      verify(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('returns Left(Failure) when DioException carries a Failure', () async {
      const failure = NotFoundFailure('Resource not found');
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      expect(result, const Left<Failure, List<Classroom>>(failure));
    });

    test(
      'returns Left(NetworkFailure) when DioException has no Failure',
      () async {
        when(
          () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
            tRequiredAuth,
            tSchoolLevelGroupId,
            tSchoolLevelId,
            tAcademicYearId,
          ),
        ).thenThrow(_dioException(error: Exception('socket error')));

        final result = await repository.getClassroomsByLevelAndAcademicYear(
          schoolLevelGroupId: tSchoolLevelGroupId,
          schoolLevelId: tSchoolLevelId,
          academicYearId: tAcademicYearId,
        );

        expect(
          result,
          const Left<Failure, List<Classroom>>(
            NetworkFailure('Network error occurred'),
          ),
        );
      },
    );

    test('returns Left(ServerFailure) when payload is invalid', () async {
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenThrow(const FormatException('Invalid payload'));

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      expect(
        result,
        const Left<Failure, List<Classroom>>(
          ServerFailure('Invalid classroom payload'),
        ),
      );
    });

    test('returns Left(ServerFailure) on unknown exception', () async {
      when(
        () => mockRemoteDataSource.listClassroomsByLevelAndAcademicYear(
          tRequiredAuth,
          tSchoolLevelGroupId,
          tSchoolLevelId,
          tAcademicYearId,
        ),
      ).thenThrow(Exception('unexpected'));

      final result = await repository.getClassroomsByLevelAndAcademicYear(
        schoolLevelGroupId: tSchoolLevelGroupId,
        schoolLevelId: tSchoolLevelId,
        academicYearId: tAcademicYearId,
      );

      expect(
        result,
        const Left<Failure, List<Classroom>>(
          ServerFailure('Unexpected error occurred'),
        ),
      );
    });
  });
}

DioException _dioException({Object? error}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/classrooms'),
    error: error,
    type: DioExceptionType.unknown,
  );
}
