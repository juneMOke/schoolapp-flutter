import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_academic_info_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class MockGetEnrollmentSummaryListByStatusUseCase extends Mock
    implements GetEnrollmentSummaryListByStatusUseCase {}

class MockGetEnrollmentDetailUseCase extends Mock
    implements GetEnrollmentDetailUseCase {}

class MockSearchByStudentNameUseCase extends Mock
    implements
        SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase {}

class MockSearchByStudentNamesAndDateOfBirthUseCase extends Mock
    implements
        SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase {}

class MockSearchByDateOfBirthUseCase extends Mock
    implements
        SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase {}

class MockSearchByAcademicInfoUseCase extends Mock
    implements SearchEnrollmentSummaryByAcademicInfoUseCase {}

const _tStudentSummary = StudentSummary(
  id: 'student-1',
  firstName: 'John',
  lastName: 'Doe',
  surname: 'Smith',
  dateOfBirth: '2010-01-01',
  gender: Gender.male,
);

final _tEnrollmentSummary = EnrollmentSummary(
  enrollmentId: 'enrollment-1',
  enrollmentCode: 'ENR-001',
  status: 'PENDING',
  student: _tStudentSummary,
);

void main() {
  late MockGetEnrollmentSummaryListByStatusUseCase
  mockGetEnrollmentSummaryListByStatusUseCase;
  late MockGetEnrollmentDetailUseCase mockGetEnrollmentDetailUseCase;
  late MockSearchByStudentNameUseCase mockSearchByStudentNameUseCase;
  late MockSearchByStudentNamesAndDateOfBirthUseCase
  mockSearchByStudentNamesAndDateOfBirthUseCase;
  late MockSearchByDateOfBirthUseCase mockSearchByDateOfBirthUseCase;
  late MockSearchByAcademicInfoUseCase mockSearchByAcademicInfoUseCase;

  setUp(() {
    mockGetEnrollmentSummaryListByStatusUseCase =
        MockGetEnrollmentSummaryListByStatusUseCase();
    mockGetEnrollmentDetailUseCase = MockGetEnrollmentDetailUseCase();
    mockSearchByStudentNameUseCase = MockSearchByStudentNameUseCase();
    mockSearchByStudentNamesAndDateOfBirthUseCase =
        MockSearchByStudentNamesAndDateOfBirthUseCase();
    mockSearchByDateOfBirthUseCase = MockSearchByDateOfBirthUseCase();
    mockSearchByAcademicInfoUseCase = MockSearchByAcademicInfoUseCase();
  });

  EnrollmentBloc buildBloc() => EnrollmentBloc(
    getEnrollmentSummariesUseCase: mockGetEnrollmentSummaryListByStatusUseCase,
    getEnrollmentDetailUseCase: mockGetEnrollmentDetailUseCase,
    searchByStudentNameUseCase: mockSearchByStudentNameUseCase,
    searchByStudentNamesAndDateOfBirthUseCase:
        mockSearchByStudentNamesAndDateOfBirthUseCase,
    searchByDateOfBirthUseCase: mockSearchByDateOfBirthUseCase,
    searchByAcademicInfoUseCase: mockSearchByAcademicInfoUseCase,
  );

  group('EnrollmentSummariesByAcademicInfoRequested', () {
    const firstName = 'John';
    const lastName = 'Doe';
    const surname = 'Smith';
    const schoolLevelGroupId = 'group-1';
    const schoolLevelId = 'level-1';

    blocTest<EnrollmentBloc, EnrollmentState>(
      'emet [loading, success] et stocke la query académique',
      setUp: () {
        when(
          () => mockSearchByAcademicInfoUseCase(
            firstName: firstName,
            lastName: lastName,
            surname: surname,
            schoolLevelGroupId: schoolLevelGroupId,
            schoolLevelId: schoolLevelId,
          ),
        ).thenAnswer((_) async => Right([_tEnrollmentSummary]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentSummariesByAcademicInfoRequested(
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          schoolLevelGroupId: schoolLevelGroupId,
          schoolLevelId: schoolLevelId,
        ),
      ),
      expect: () => [
        isA<EnrollmentState>()
            .having(
              (s) => s.summariesStatus,
              'summariesStatus',
              EnrollmentLoadStatus.loading,
            )
            .having(
              (s) => s.summariesQueryType,
              'summariesQueryType',
              EnrollmentSummaryQueryType.byAcademicInfo,
            )
            .having(
              (s) => s.lastSummariesQuery?.firstName,
              'firstName',
              firstName,
            )
            .having(
              (s) => s.lastSummariesQuery?.schoolLevelGroupId,
              'schoolLevelGroupId',
              schoolLevelGroupId,
            ),
        isA<EnrollmentState>()
            .having(
              (s) => s.summariesStatus,
              'summariesStatus',
              EnrollmentLoadStatus.success,
            )
            .having(
              (s) => s.summariesQueryType,
              'summariesQueryType',
              EnrollmentSummaryQueryType.byAcademicInfo,
            )
            .having((s) => s.summaries.length, 'summaries.length', 1)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(
          () => mockSearchByAcademicInfoUseCase(
            firstName: firstName,
            lastName: lastName,
            surname: surname,
            schoolLevelGroupId: schoolLevelGroupId,
            schoolLevelId: schoolLevelId,
          ),
        ).called(1);
      },
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'emet [loading, failure] quand le use case renvoie une erreur',
      setUp: () {
        when(
          () => mockSearchByAcademicInfoUseCase(
            firstName: firstName,
            lastName: lastName,
            surname: surname,
            schoolLevelGroupId: schoolLevelGroupId,
            schoolLevelId: schoolLevelId,
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('Server unavailable')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentSummariesByAcademicInfoRequested(
          firstName: firstName,
          lastName: lastName,
          surname: surname,
          schoolLevelGroupId: schoolLevelGroupId,
          schoolLevelId: schoolLevelId,
        ),
      ),
      expect: () => [
        isA<EnrollmentState>()
            .having(
              (s) => s.summariesStatus,
              'summariesStatus',
              EnrollmentLoadStatus.loading,
            )
            .having(
              (s) => s.summariesQueryType,
              'summariesQueryType',
              EnrollmentSummaryQueryType.byAcademicInfo,
            ),
        isA<EnrollmentState>()
            .having(
              (s) => s.summariesStatus,
              'summariesStatus',
              EnrollmentLoadStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Server unavailable',
            ),
      ],
      verify: (_) {
        verify(
          () => mockSearchByAcademicInfoUseCase(
            firstName: firstName,
            lastName: lastName,
            surname: surname,
            schoolLevelGroupId: schoolLevelGroupId,
            schoolLevelId: schoolLevelId,
          ),
        ).called(1);
      },
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'rejoue la dernière query académique sur refresh',
      setUp: () {
        when(
          () => mockSearchByAcademicInfoUseCase(
            firstName: firstName,
            lastName: lastName,
            surname: surname,
            schoolLevelGroupId: schoolLevelGroupId,
            schoolLevelId: schoolLevelId,
          ),
        ).thenAnswer((_) async => Right([_tEnrollmentSummary]));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          const EnrollmentSummariesByAcademicInfoRequested(
            firstName: firstName,
            lastName: lastName,
            surname: surname,
            schoolLevelGroupId: schoolLevelGroupId,
            schoolLevelId: schoolLevelId,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EnrollmentSummariesRefreshRequested());
      },
      expect: () => [
        isA<EnrollmentState>().having(
          (s) => s.summariesStatus,
          'summariesStatus',
          EnrollmentLoadStatus.loading,
        ),
        isA<EnrollmentState>().having(
          (s) => s.summariesStatus,
          'summariesStatus',
          EnrollmentLoadStatus.success,
        ),
        isA<EnrollmentState>().having(
          (s) => s.summariesStatus,
          'summariesStatus',
          EnrollmentLoadStatus.loading,
        ),
        isA<EnrollmentState>().having(
          (s) => s.summariesStatus,
          'summariesStatus',
          EnrollmentLoadStatus.success,
        ),
      ],
      verify: (_) {
        verify(
          () => mockSearchByAcademicInfoUseCase(
            firstName: firstName,
            lastName: lastName,
            surname: surname,
            schoolLevelGroupId: schoolLevelGroupId,
            schoolLevelId: schoolLevelId,
          ),
        ).called(2);
      },
    );
  });
}
