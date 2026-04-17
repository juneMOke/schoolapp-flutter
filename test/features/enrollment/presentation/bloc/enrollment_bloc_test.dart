import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_preview_by_student_id_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_academic_info_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockGetEnrollmentSummaryListByStatusUseCase extends Mock
    implements GetEnrollmentSummaryListByStatusUseCase {}

class MockGetEnrollmentDetailUseCase extends Mock
    implements GetEnrollmentDetailUseCase {}

class MockGetEnrollmentPreviewByStudentIdUseCase extends Mock
    implements GetEnrollmentPreviewByStudentIdUseCase {}

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

// ─── Fixtures ─────────────────────────────────────────────────────────────────

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

final _tEnrollmentDetail = EnrollmentDetail(
  studentDetail: const StudentDetail(
    id: 'student-1',
    firstName: 'John',
    lastName: 'Doe',
    surname: 'Smith',
    dateOfBirth: '2010-01-01',
    gender: Gender.male,
    birthPlace: 'Kinshasa',
    nationality: 'Congolaise',
    city: 'Kinshasa',
    district: 'Gombe',
    municipality: 'Gombe',
    address: '123 Rue Test',
    schoolLevel: SchoolLevel(
      id: 'level-1',
      name: '6ème',
      code: '6EME',
      displayOrder: 1,
    ),
    schoolLevelGroup: SchoolLevelGroup(
      id: 'group-1',
      name: 'Primaire',
      code: 'PRI',
    ),
  ),
  parentDetails: const [],
  enrollmentDetail: const EnrollmentSchoolDetail(
    id: 'enrollment-1',
    status: EnrollmentStatus.pending,
    academicYearId: 'year-1',
    enrollmentCode: 'ENR-001',
    previousSchoolName: 'École Test',
    previousAcademicYear: '2024-2025',
    previousSchoolLevelGroup: 'Primaire',
    previousSchoolLevel: '5ème',
    previousRate: 75.0,
    validatedPreviousYear: true,
    schoolLevelGroupId: 'group-1',
    schoolLevelId: 'level-1',
  ),
);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockGetEnrollmentSummaryListByStatusUseCase
  mockGetEnrollmentSummaryListByStatusUseCase;
  late MockGetEnrollmentDetailUseCase mockGetEnrollmentDetailUseCase;
  late MockGetEnrollmentPreviewByStudentIdUseCase
  mockGetEnrollmentPreviewByStudentIdUseCase;
  late MockSearchByStudentNameUseCase mockSearchByStudentNameUseCase;
  late MockSearchByStudentNamesAndDateOfBirthUseCase
  mockSearchByStudentNamesAndDateOfBirthUseCase;
  late MockSearchByDateOfBirthUseCase mockSearchByDateOfBirthUseCase;
  late MockSearchByAcademicInfoUseCase mockSearchByAcademicInfoUseCase;

  setUp(() {
    mockGetEnrollmentSummaryListByStatusUseCase =
        MockGetEnrollmentSummaryListByStatusUseCase();
    mockGetEnrollmentDetailUseCase = MockGetEnrollmentDetailUseCase();
    mockGetEnrollmentPreviewByStudentIdUseCase =
        MockGetEnrollmentPreviewByStudentIdUseCase();
    mockSearchByStudentNameUseCase = MockSearchByStudentNameUseCase();
    mockSearchByStudentNamesAndDateOfBirthUseCase =
        MockSearchByStudentNamesAndDateOfBirthUseCase();
    mockSearchByDateOfBirthUseCase = MockSearchByDateOfBirthUseCase();
    mockSearchByAcademicInfoUseCase = MockSearchByAcademicInfoUseCase();
  });

  EnrollmentBloc buildBloc() => EnrollmentBloc(
    getEnrollmentSummariesUseCase: mockGetEnrollmentSummaryListByStatusUseCase,
    getEnrollmentDetailUseCase: mockGetEnrollmentDetailUseCase,
    getEnrollmentPreviewByStudentIdUseCase:
        mockGetEnrollmentPreviewByStudentIdUseCase,
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

  group('EnrollmentDetailRequested', () {
    const enrollmentId = 'enrollment-1';

    blocTest<EnrollmentBloc, EnrollmentState>(
      'emet uniquement [success] en mode silent pour préserver le stepper',
      setUp: () {
        when(
          () => mockGetEnrollmentDetailUseCase(enrollmentId: enrollmentId),
        ).thenAnswer((_) async => Right(_tEnrollmentDetail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentDetailRequested(
          enrollmentId: enrollmentId,
          silent: true,
        ),
      ),
      expect: () => [
        isA<EnrollmentState>()
            .having(
              (s) => s.detailStatus,
              'detailStatus',
              EnrollmentLoadStatus.success,
            )
            .having((s) => s.detail, 'detail', isNotNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(
          () => mockGetEnrollmentDetailUseCase(enrollmentId: enrollmentId),
        ).called(1);
      },
    );
  });

  group('EnrollmentPreviewByStudentIdRequested', () {
    const studentId = 'student-1';

    blocTest<EnrollmentBloc, EnrollmentState>(
      'emet [previewLoading, previewSuccess] avec le détail pré-rempli',
      setUp: () {
        when(
          () =>
              mockGetEnrollmentPreviewByStudentIdUseCase(studentId: studentId),
        ).thenAnswer((_) async => Right(_tEnrollmentDetail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentPreviewByStudentIdRequested(studentId: studentId),
      ),
      expect: () => [
        isA<EnrollmentState>()
            .having(
              (s) => s.previewStatus,
              'previewStatus',
              EnrollmentLoadStatus.loading,
            )
            .having((s) => s.preview, 'preview', isNull),
        isA<EnrollmentState>()
            .having(
              (s) => s.previewStatus,
              'previewStatus',
              EnrollmentLoadStatus.success,
            )
            .having((s) => s.preview, 'preview', isNotNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(
          () =>
              mockGetEnrollmentPreviewByStudentIdUseCase(studentId: studentId),
        ).called(1);
      },
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'emet [previewLoading, previewFailure] quand le use case renvoie une erreur',
      setUp: () {
        when(
          () =>
              mockGetEnrollmentPreviewByStudentIdUseCase(studentId: studentId),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('Preview unavailable')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentPreviewByStudentIdRequested(studentId: studentId),
      ),
      expect: () => [
        isA<EnrollmentState>().having(
          (s) => s.previewStatus,
          'previewStatus',
          EnrollmentLoadStatus.loading,
        ),
        isA<EnrollmentState>()
            .having(
              (s) => s.previewStatus,
              'previewStatus',
              EnrollmentLoadStatus.failure,
            )
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              'Preview unavailable',
            )
            .having((s) => s.preview, 'preview', isNull),
      ],
      verify: (_) {
        verify(
          () =>
              mockGetEnrollmentPreviewByStudentIdUseCase(studentId: studentId),
        ).called(1);
      },
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'ne modifie pas summariesStatus ni detail lors du chargement du preview',
      setUp: () {
        when(
          () =>
              mockGetEnrollmentPreviewByStudentIdUseCase(studentId: studentId),
        ).thenAnswer((_) async => Right(_tEnrollmentDetail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentPreviewByStudentIdRequested(studentId: studentId),
      ),
      expect: () => [
        isA<EnrollmentState>()
            .having(
              (s) => s.summariesStatus,
              'summariesStatus',
              EnrollmentLoadStatus.initial,
            )
            .having(
              (s) => s.detailStatus,
              'detailStatus',
              EnrollmentLoadStatus.initial,
            ),
        isA<EnrollmentState>()
            .having(
              (s) => s.summariesStatus,
              'summariesStatus',
              EnrollmentLoadStatus.initial,
            )
            .having(
              (s) => s.detailStatus,
              'detailStatus',
              EnrollmentLoadStatus.initial,
            ),
      ],
    );

    blocTest<EnrollmentBloc, EnrollmentState>(
      'emet uniquement [previewSuccess] en mode silent pour préserver le stepper',
      setUp: () {
        when(
          () =>
              mockGetEnrollmentPreviewByStudentIdUseCase(studentId: studentId),
        ).thenAnswer((_) async => Right(_tEnrollmentDetail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const EnrollmentPreviewByStudentIdRequested(
          studentId: studentId,
          silent: true,
        ),
      ),
      expect: () => [
        isA<EnrollmentState>()
            .having(
              (s) => s.previewStatus,
              'previewStatus',
              EnrollmentLoadStatus.success,
            )
            .having((s) => s.preview, 'preview', isNotNull)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verify(
          () =>
              mockGetEnrollmentPreviewByStudentIdUseCase(studentId: studentId),
        ).called(1);
      },
    );
  });
}
