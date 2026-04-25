import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/update_student_charge_expected_amount_usecase.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';

class MockGetStudentChargesUseCase extends Mock
    implements GetStudentChargesUseCase {}

class MockUpdateStudentChargeExpectedAmountUseCase extends Mock
    implements UpdateStudentChargeExpectedAmountUseCase {}

class MockGetStudentChargesByAcademicYearUseCase extends Mock
    implements GetStudentChargesByAcademicYearUseCase {}

const tStudentId = 'student-1';
const tLevelId = 'level-1';
const tParams = GetStudentChargesParams(
  studentId: tStudentId,
  levelId: tLevelId,
);

const tUpdateParams = UpdateStudentChargeExpectedAmountParams(
  studentChargeId: 'charge-1',
  studentId: tStudentId,
  expectedAmountInCents: 175000,
);

const tCharge = StudentCharge(
  id: 'charge-1',
  studentId: tStudentId,
  academicYearId: 'year-1',
  schoolLevelId: tLevelId,
  schoolLevelGroupId: 'group-1',
  feeTariffId: 'tariff-1',
  feeCode: 'TUITION',
  label: 'Frais de scolarité',
  expectedAmountInCents: 150000,
  amountPaidInCents: 50000,
  currency: 'USD',
  status: StudentChargeStatus.partial,
);

const tUpdatedCharge = StudentCharge(
  id: 'charge-1',
  studentId: tStudentId,
  academicYearId: 'year-1',
  schoolLevelId: tLevelId,
  schoolLevelGroupId: 'group-1',
  feeTariffId: 'tariff-1',
  feeCode: 'TUITION',
  label: 'Frais de scolarité',
  expectedAmountInCents: 175000,
  amountPaidInCents: 50000,
  currency: 'USD',
  status: StudentChargeStatus.partial,
);

void main() {
  late MockGetStudentChargesUseCase mockGetStudentChargesUseCase;
  late MockUpdateStudentChargeExpectedAmountUseCase
  mockUpdateStudentChargeExpectedAmountUseCase;
  late MockGetStudentChargesByAcademicYearUseCase
      mockGetStudentChargesByAcademicYearUseCase;

  setUp(() {
    mockGetStudentChargesUseCase = MockGetStudentChargesUseCase();
    mockUpdateStudentChargeExpectedAmountUseCase =
        MockUpdateStudentChargeExpectedAmountUseCase();
    mockGetStudentChargesByAcademicYearUseCase =
        MockGetStudentChargesByAcademicYearUseCase();
  });

  StudentChargesBloc buildBloc() => StudentChargesBloc(
    getStudentChargesUseCase: mockGetStudentChargesUseCase,
    getStudentChargesByAcademicYearUseCase:
        mockGetStudentChargesByAcademicYearUseCase,
    updateStudentChargeExpectedAmountUseCase:
        mockUpdateStudentChargeExpectedAmountUseCase,
  );

  group('StudentChargesRequested', () {
    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits [loading, success] when student charges are loaded',
      setUp: () {
        when(
          () => mockGetStudentChargesUseCase(tParams),
        ).thenAnswer((_) async => const Right([tCharge]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const StudentChargesRequested(studentId: tStudentId, levelId: tLevelId),
      ),
      expect: () => const [
        StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [tCharge],
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits failure with notFound error type on NotFoundFailure',
      setUp: () {
        when(() => mockGetStudentChargesUseCase(tParams)).thenAnswer(
          (_) async => const Left(NotFoundFailure('Resource not found')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const StudentChargesRequested(studentId: tStudentId, levelId: tLevelId),
      ),
      expect: () => const [
        StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.failure,
          errorType: StudentChargesErrorType.notFound,
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits failure with validation error type on ValidationFailure',
      setUp: () {
        when(() => mockGetStudentChargesUseCase(tParams)).thenAnswer(
          (_) async => const Left(ValidationFailure('Invalid request data')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const StudentChargesRequested(studentId: tStudentId, levelId: tLevelId),
      ),
      expect: () => const [
        StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.failure,
          errorType: StudentChargesErrorType.validation,
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits failure with network error type on NetworkFailure',
      setUp: () {
        when(() => mockGetStudentChargesUseCase(tParams)).thenAnswer(
          (_) async => const Left(NetworkFailure('Network error occurred')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const StudentChargesRequested(studentId: tStudentId, levelId: tLevelId),
      ),
      expect: () => const [
        StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.failure,
          errorType: StudentChargesErrorType.network,
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits success with locally updated charges when draft is saved',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const StudentChargesDraftSaved(studentCharges: [tUpdatedCharge]),
      ),
      expect: () => const [
        StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [tUpdatedCharge],
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits [loading, success] and replaces the updated charge when update succeeds',
      setUp: () {
        when(
          () => mockUpdateStudentChargeExpectedAmountUseCase(tUpdateParams),
        ).thenAnswer((_) async => const Right(tUpdatedCharge));
      },
      build: buildBloc,
      seed: () => const StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [tCharge],
      ),
      act: (bloc) => bloc.add(
        const StudentChargeExpectedAmountUpdateRequested(
          studentChargeId: 'charge-1',
          studentId: tStudentId,
          expectedAmountInCents: 175000,
        ),
      ),
      expect: () => const [
        StudentChargesState(
          status: StudentChargesStatus.loading,
          studentCharges: [tCharge],
          updatingChargeId: 'charge-1',
        ),
        StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [tUpdatedCharge],
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits failure with validation error type when update request is invalid',
      setUp: () {
        when(
          () => mockUpdateStudentChargeExpectedAmountUseCase(tUpdateParams),
        ).thenAnswer(
          (_) async => const Left(ValidationFailure('Invalid request data')),
        );
      },
      build: buildBloc,
      seed: () => const StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [tCharge],
      ),
      act: (bloc) => bloc.add(
        const StudentChargeExpectedAmountUpdateRequested(
          studentChargeId: 'charge-1',
          studentId: tStudentId,
          expectedAmountInCents: 175000,
        ),
      ),
      expect: () => const [
        StudentChargesState(
          status: StudentChargesStatus.loading,
          studentCharges: [tCharge],
          updatingChargeId: 'charge-1',
        ),
        StudentChargesState(
          status: StudentChargesStatus.failure,
          studentCharges: [tCharge],
          errorType: StudentChargesErrorType.validation,
          updatingChargeId: 'charge-1',
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'emits failure with notFound error type when updated charge does not exist',
      setUp: () {
        when(
          () => mockUpdateStudentChargeExpectedAmountUseCase(tUpdateParams),
        ).thenAnswer(
          (_) async => const Left(NotFoundFailure('Resource not found')),
        );
      },
      build: buildBloc,
      seed: () => const StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [tCharge],
      ),
      act: (bloc) => bloc.add(
        const StudentChargeExpectedAmountUpdateRequested(
          studentChargeId: 'charge-1',
          studentId: tStudentId,
          expectedAmountInCents: 175000,
        ),
      ),
      expect: () => const [
        StudentChargesState(
          status: StudentChargesStatus.loading,
          studentCharges: [tCharge],
          updatingChargeId: 'charge-1',
        ),
        StudentChargesState(
          status: StudentChargesStatus.failure,
          studentCharges: [tCharge],
          errorType: StudentChargesErrorType.notFound,
          updatingChargeId: 'charge-1',
        ),
      ],
    );
  });
}
