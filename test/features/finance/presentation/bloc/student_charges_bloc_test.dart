import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_payment_allocations_from_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/update_student_charge_expected_amount_usecase.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/initialize_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';

class MockGetStudentChargesUseCase extends Mock
    implements GetStudentChargesUseCase {}

class MockInitializeChargesUseCase extends Mock
    implements InitializeChargesUseCase {}

class MockUpdateStudentChargeExpectedAmountUseCase extends Mock
    implements UpdateStudentChargeExpectedAmountUseCase {}

class MockGetStudentChargesByAcademicYearUseCase extends Mock
    implements GetStudentChargesByAcademicYearUseCase {}

class MockGetPaymentAllocationsFromStudentChargesUseCase extends Mock
    implements GetPaymentAllocationsFromStudentChargesUseCase {}

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
  late MockGetPaymentAllocationsFromStudentChargesUseCase
  mockGetPaymentAllocationsFromStudentChargesUseCase;

  setUp(() {
    mockGetStudentChargesUseCase = MockGetStudentChargesUseCase();
    mockUpdateStudentChargeExpectedAmountUseCase =
        MockUpdateStudentChargeExpectedAmountUseCase();
    mockGetStudentChargesByAcademicYearUseCase =
        MockGetStudentChargesByAcademicYearUseCase();
    mockGetPaymentAllocationsFromStudentChargesUseCase =
        MockGetPaymentAllocationsFromStudentChargesUseCase();
  });

  StudentChargesBloc buildBloc() => StudentChargesBloc(
    getStudentChargesUseCase: mockGetStudentChargesUseCase,
    getStudentChargesByAcademicYearUseCase:
        mockGetStudentChargesByAcademicYearUseCase,
    getPaymentAllocationsFromStudentChargesUseCase:
        mockGetPaymentAllocationsFromStudentChargesUseCase,
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

  group('DraftStudentChargesRequested (wizard brouillon, FF5)', () {
    late MockInitializeChargesUseCase mockInitializeChargesUseCase;

    setUp(() {
      mockInitializeChargesUseCase = MockInitializeChargesUseCase();
    });

    StudentChargesBloc buildDraftBloc() => StudentChargesBloc(
      getStudentChargesUseCase: mockGetStudentChargesUseCase,
      getStudentChargesByAcademicYearUseCase:
          mockGetStudentChargesByAcademicYearUseCase,
      getPaymentAllocationsFromStudentChargesUseCase:
          mockGetPaymentAllocationsFromStudentChargesUseCase,
      updateStudentChargeExpectedAmountUseCase:
          mockUpdateStudentChargeExpectedAmountUseCase,
      initializeChargesUseCase: mockInitializeChargesUseCase,
    );

    const tDraftEvent = DraftStudentChargesRequested(
      studentId: tStudentId,
      levelId: tLevelId,
      academicYearId: 'year-1',
      schoolLevelGroupId: 'group-1',
    );

    void stubInitialize(Either<Failure, List<LocalStudentCharge>> answer) {
      when(
        () => mockInitializeChargesUseCase(
          studentId: tStudentId,
          academicYearId: 'year-1',
          schoolLevelId: tLevelId,
          schoolLevelGroupId: 'group-1',
        ),
      ).thenAnswer((_) async => answer);
    }

    blocTest<StudentChargesBloc, StudentChargesState>(
      'génère les créances locales PUIS lit le grand-livre → [loading, success]',
      setUp: () {
        stubInitialize(const Right(<LocalStudentCharge>[]));
        when(
          () => mockGetStudentChargesUseCase(tParams),
        ).thenAnswer((_) async => const Right([tCharge]));
      },
      build: buildDraftBloc,
      act: (bloc) => bloc.add(tDraftEvent),
      expect: () => const [
        StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [tCharge],
        ),
      ],
      verify: (_) {
        verify(
          () => mockInitializeChargesUseCase(
            studentId: tStudentId,
            academicYearId: 'year-1',
            schoolLevelId: tLevelId,
            schoolLevelGroupId: 'group-1',
          ),
        ).called(1);
      },
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'échec de génération → failure storage, pas de lecture faussement vide',
      setUp: () {
        stubInitialize(const Left(StorageFailure('boom')));
      },
      build: buildDraftBloc,
      act: (bloc) => bloc.add(tDraftEvent),
      expect: () => const [
        StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.failure,
          errorType: StudentChargesErrorType.storage,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockGetStudentChargesUseCase(tParams));
      },
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'lecture scopée sur l\'année du dossier : les créances N-1 sont '
      'filtrées, celles à année vide restent rattachées',
      setUp: () {
        stubInitialize(const Right(<LocalStudentCharge>[]));
        when(() => mockGetStudentChargesUseCase(tParams)).thenAnswer(
          (_) async => Right([
            tCharge,
            tCharge.copyWith(id: 'charge-n1', academicYearId: 'year-0'),
            tCharge.copyWith(id: 'charge-legacy', academicYearId: ''),
          ]),
        );
      },
      build: buildDraftBloc,
      act: (bloc) => bloc.add(tDraftEvent),
      expect: () => [
        const StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [
            tCharge,
            tCharge.copyWith(id: 'charge-legacy', academicYearId: ''),
          ],
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'academicYearId vide-mais-non-null (pas null) → traité comme "pas de '
      'scope", ne wipe pas les créances réelles',
      setUp: () {
        stubInitialize(const Right(<LocalStudentCharge>[]));
        when(() => mockGetStudentChargesUseCase(tParams)).thenAnswer(
          (_) async => Right([
            tCharge,
            tCharge.copyWith(id: 'charge-n1', academicYearId: 'year-0'),
          ]),
        );
      },
      build: buildDraftBloc,
      act: (bloc) => bloc.add(
        const DraftStudentChargesRequested(
          studentId: tStudentId,
          levelId: tLevelId,
          academicYearId: '', // vide-mais-non-null
          schoolLevelGroupId: 'group-1',
        ),
      ),
      expect: () => [
        const StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [
            tCharge,
            tCharge.copyWith(id: 'charge-n1', academicYearId: 'year-0'),
          ],
        ),
      ],
    );

    blocTest<StudentChargesBloc, StudentChargesState>(
      'usecase FF5 absent (bloc hors wizard) → dégrade en simple lecture',
      setUp: () {
        when(
          () => mockGetStudentChargesUseCase(tParams),
        ).thenAnswer((_) async => const Right([tCharge]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(tDraftEvent),
      expect: () => const [
        StudentChargesState(status: StudentChargesStatus.loading),
        StudentChargesState(
          status: StudentChargesStatus.success,
          studentCharges: [tCharge],
        ),
      ],
    );
  });
}
