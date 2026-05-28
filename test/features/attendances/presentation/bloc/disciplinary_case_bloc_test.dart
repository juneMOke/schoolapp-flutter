import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_detail.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/create_disciplinary_case_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_disciplinary_case_detail_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_disciplinary_case_list_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';

class MockGetDisciplinaryCaseListUseCase extends Mock
    implements GetDisciplinaryCaseListUseCase {}

class MockGetDisciplinaryCaseDetailUseCase extends Mock
    implements GetDisciplinaryCaseDetailUseCase {}

class MockCreateDisciplinaryCaseUseCase extends Mock
    implements CreateDisciplinaryCaseUseCase {}

final tSummary = const DisciplinaryCaseSummary(
  id: 'case-1',
  studentId: 'student-1',
  studentFirstName: 'Aline',
  studentLastName: 'Mukendi',
  studentMiddleName: 'Grace',
  studentGender: StudentGender.female,
  academicYearId: 'year-1',
  title: 'Repeated lateness',
  status: DisciplinaryCaseStatus.open,
  content: 'The student arrived late three times this week.',
);

final tDetail = const DisciplinaryCaseDetail(
  id: 'case-1',
  studentId: 'student-1',
  studentFirstName: 'Aline',
  studentLastName: 'Mukendi',
  studentMiddleName: 'Grace',
  studentGender: StudentGender.female,
  academicYearId: 'year-1',
  title: 'Repeated lateness',
  status: DisciplinaryCaseStatus.open,
  content: 'The student arrived late three times this week.',
);

final tDate = DateTime(2026, 4, 30);

void main() {
  late MockGetDisciplinaryCaseListUseCase mockGetDisciplinaryCaseListUseCase;
  late MockGetDisciplinaryCaseDetailUseCase
  mockGetDisciplinaryCaseDetailUseCase;
  late MockCreateDisciplinaryCaseUseCase mockCreateDisciplinaryCaseUseCase;

  setUp(() {
    mockGetDisciplinaryCaseListUseCase = MockGetDisciplinaryCaseListUseCase();
    mockGetDisciplinaryCaseDetailUseCase =
        MockGetDisciplinaryCaseDetailUseCase();
    mockCreateDisciplinaryCaseUseCase = MockCreateDisciplinaryCaseUseCase();
  });

  DisciplinaryCaseBloc buildBloc() => DisciplinaryCaseBloc(
    getDisciplinaryCaseListUseCase: mockGetDisciplinaryCaseListUseCase,
    getDisciplinaryCaseDetailUseCase: mockGetDisciplinaryCaseDetailUseCase,
    createDisciplinaryCaseUseCase: mockCreateDisciplinaryCaseUseCase,
  );

  group('DisciplinaryCaseListRequested', () {
    blocTest<DisciplinaryCaseBloc, DisciplinaryCaseState>(
      'emits loading then success with fetched list',
      setUp: () {
        when(
          () => mockGetDisciplinaryCaseListUseCase(
            studentId: 'student-1',
            academicYearId: 'year-1',
          ),
        ).thenAnswer((_) async => Right([tSummary]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const DisciplinaryCaseListRequested(
          studentId: 'student-1',
          academicYearId: 'year-1',
        ),
      ),
      expect: () => [
        const DisciplinaryCaseState(
          listStatus: DisciplinaryCaseStatusState.loading,
        ),
        DisciplinaryCaseState(
          listStatus: DisciplinaryCaseStatusState.success,
          cases: [tSummary],
        ),
      ],
    );
  });

  group('DisciplinaryCaseDetailRequested', () {
    blocTest<DisciplinaryCaseBloc, DisciplinaryCaseState>(
      'maps not found failure to detail error type',
      setUp: () {
        when(
          () => mockGetDisciplinaryCaseDetailUseCase(caseId: 'missing-case'),
        ).thenAnswer((_) async => const Left(NotFoundFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const DisciplinaryCaseDetailRequested(caseId: 'missing-case'),
      ),
      expect: () => [
        const DisciplinaryCaseState(
          detailStatus: DisciplinaryCaseStatusState.loading,
        ),
        const DisciplinaryCaseState(
          detailStatus: DisciplinaryCaseStatusState.failure,
          detailErrorType: DisciplinaryCaseErrorType.notFound,
        ),
      ],
    );
  });

  group('DisciplinaryCaseCreateRequested', () {
    blocTest<DisciplinaryCaseBloc, DisciplinaryCaseState>(
      'emits loading then success and prepends created case to list',
      setUp: () {
        when(
          () => mockCreateDisciplinaryCaseUseCase(
            studentId: 'student-1',
            studentFirstName: 'Aline',
            studentLastName: 'Mukendi',
            studentMiddleName: 'Grace',
            studentGender: StudentGender.female,
            disciplinaryCaseDate: tDate,
            academicYearId: 'year-1',
            title: 'Repeated lateness',
            content: 'The student arrived late three times this week.',
          ),
        ).thenAnswer((_) async => Right(tSummary));
      },
      build: buildBloc,
      seed: () => const DisciplinaryCaseState(cases: []),
      act: (bloc) => bloc.add(
        DisciplinaryCaseCreateRequested(
          studentId: 'student-1',
          studentFirstName: 'Aline',
          studentLastName: 'Mukendi',
          studentMiddleName: 'Grace',
          studentGender: StudentGender.female,
          disciplinaryCaseDate: tDate,
          academicYearId: 'year-1',
          title: 'Repeated lateness',
          content: 'The student arrived late three times this week.',
        ),
      ),
      expect: () => [
        const DisciplinaryCaseState(
          createStatus: DisciplinaryCaseStatusState.loading,
          cases: [],
        ),
        DisciplinaryCaseState(
          createStatus: DisciplinaryCaseStatusState.success,
          createdCase: tSummary,
          cases: [tSummary],
        ),
      ],
      verify: (_) {
        verify(
          () => mockCreateDisciplinaryCaseUseCase(
            studentId: 'student-1',
            studentFirstName: 'Aline',
            studentLastName: 'Mukendi',
            studentMiddleName: 'Grace',
            studentGender: StudentGender.female,
            disciplinaryCaseDate: tDate,
            academicYearId: 'year-1',
            title: 'Repeated lateness',
            content: 'The student arrived late three times this week.',
          ),
        ).called(1);
      },
    );

    blocTest<DisciplinaryCaseBloc, DisciplinaryCaseState>(
      'loads detail successfully',
      setUp: () {
        when(
          () => mockGetDisciplinaryCaseDetailUseCase(caseId: 'case-1'),
        ).thenAnswer((_) async => Right(tDetail));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const DisciplinaryCaseDetailRequested(caseId: 'case-1')),
      expect: () => [
        const DisciplinaryCaseState(
          detailStatus: DisciplinaryCaseStatusState.loading,
        ),
        DisciplinaryCaseState(
          detailStatus: DisciplinaryCaseStatusState.success,
          selectedCase: tDetail,
        ),
      ],
    );
  });
}
