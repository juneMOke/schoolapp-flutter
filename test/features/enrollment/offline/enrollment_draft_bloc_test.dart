import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/finalize_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_draft_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_address_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_guardians_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_identity_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_previous_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_target_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/start_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';

class MockStartDraftUseCase extends Mock implements StartDraftUseCase {}

class MockSaveDraftIdentityUseCase extends Mock
    implements SaveDraftIdentityUseCase {}

class MockSaveDraftAddressUseCase extends Mock
    implements SaveDraftAddressUseCase {}

class MockSaveDraftPreviousAcademicUseCase extends Mock
    implements SaveDraftPreviousAcademicUseCase {}

class MockSaveDraftTargetAcademicUseCase extends Mock
    implements SaveDraftTargetAcademicUseCase {}

class MockSaveDraftGuardiansUseCase extends Mock
    implements SaveDraftGuardiansUseCase {}

class MockGetDraftDetailUseCase extends Mock implements GetDraftDetailUseCase {}

class MockFinalizeDraftUseCase extends Mock implements FinalizeDraftUseCase {}

void main() {
  late MockStartDraftUseCase startDraft;
  late MockSaveDraftIdentityUseCase saveIdentity;
  late MockSaveDraftAddressUseCase saveAddress;
  late MockSaveDraftPreviousAcademicUseCase savePreviousAcademic;
  late MockSaveDraftTargetAcademicUseCase saveTargetAcademic;
  late MockSaveDraftGuardiansUseCase saveGuardians;
  late MockGetDraftDetailUseCase getDetail;
  late MockFinalizeDraftUseCase finalize;

  const detail = LocalEnrollmentDetail(
    enrollment: LocalEnrollment(
      id: 'e1',
      studentId: 's1',
      enrollmentType: EnrollmentType.newEnrollment,
      status: OfflineEnrollmentStatus.inProgress,
      academicYearId: 'ay-2026',
      enrollmentDate: '2026-07-06',
      syncState: SyncState.draft,
    ),
    student: LocalStudent(
      id: 's1',
      firstName: 'Amina',
      lastName: 'Moke',
      gender: OfflineGender.female,
      dateOfBirth: '2015-04-02',
      syncState: SyncState.draft,
    ),
  );

  setUp(() {
    startDraft = MockStartDraftUseCase();
    saveIdentity = MockSaveDraftIdentityUseCase();
    saveAddress = MockSaveDraftAddressUseCase();
    savePreviousAcademic = MockSaveDraftPreviousAcademicUseCase();
    saveTargetAcademic = MockSaveDraftTargetAcademicUseCase();
    saveGuardians = MockSaveDraftGuardiansUseCase();
    getDetail = MockGetDraftDetailUseCase();
    finalize = MockFinalizeDraftUseCase();
  });

  EnrollmentDraftBloc buildBloc() => EnrollmentDraftBloc(
    startDraft: startDraft,
    saveIdentity: saveIdentity,
    saveAddress: saveAddress,
    savePreviousAcademic: savePreviousAcademic,
    saveTargetAcademic: saveTargetAcademic,
    saveGuardians: saveGuardians,
    getDetail: getDetail,
    finalize: finalize,
  );

  blocTest<EnrollmentDraftBloc, EnrollmentDraftState>(
    'StartDraftRequested → [Started(ids)]',
    setUp: () {
      when(
        () => startDraft(existingStudentId: any(named: 'existingStudentId')),
      ).thenReturn(const DraftIds(enrollmentId: 'e1', studentId: 's1'));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const StartDraftRequested()),
    expect: () => const [EnrollmentDraftStarted('e1', 's1')],
  );

  blocTest<EnrollmentDraftBloc, EnrollmentDraftState>(
    'SaveDraftIdentityRequested succès → [Saving, StepSaved]',
    setUp: () {
      when(
        () => saveIdentity(
          enrollmentId: any(named: 'enrollmentId'),
          studentId: any(named: 'studentId'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          gender: any(named: 'gender'),
          dateOfBirth: any(named: 'dateOfBirth'),
          birthPlace: any(named: 'birthPlace'),
          nationality: any(named: 'nationality'),
          matriculationNumber: any(named: 'matriculationNumber'),
          enrollmentType: any(named: 'enrollmentType'),
          status: any(named: 'status'),
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          enrollmentDate: any(named: 'enrollmentDate'),
        ),
      ).thenAnswer((_) async => const Right(unit));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const SaveDraftIdentityRequested(
        enrollmentId: 'e1',
        studentId: 's1',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-2026',
        enrollmentDate: '2026-07-06',
      ),
    ),
    expect: () => const [EnrollmentDraftSaving(), EnrollmentDraftStepSaved()],
  );

  blocTest<EnrollmentDraftBloc, EnrollmentDraftState>(
    'SaveDraftIdentityRequested échec → [Saving, Error]',
    setUp: () {
      when(
        () => saveIdentity(
          enrollmentId: any(named: 'enrollmentId'),
          studentId: any(named: 'studentId'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          surname: any(named: 'surname'),
          gender: any(named: 'gender'),
          dateOfBirth: any(named: 'dateOfBirth'),
          birthPlace: any(named: 'birthPlace'),
          nationality: any(named: 'nationality'),
          matriculationNumber: any(named: 'matriculationNumber'),
          enrollmentType: any(named: 'enrollmentType'),
          status: any(named: 'status'),
          academicYearId: any(named: 'academicYearId'),
          schoolLevelId: any(named: 'schoolLevelId'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
          enrollmentDate: any(named: 'enrollmentDate'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure()));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const SaveDraftIdentityRequested(
        enrollmentId: 'e1',
        studentId: 's1',
        firstName: 'Amina',
        lastName: 'Moke',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        enrollmentType: 'NEW_ENROLLMENT',
        status: 'IN_PROGRESS',
        academicYearId: 'ay-2026',
        enrollmentDate: '2026-07-06',
      ),
    ),
    expect: () => const [
      EnrollmentDraftSaving(),
      EnrollmentDraftError('Erreur d\'accès à la base locale.'),
    ],
  );

  blocTest<EnrollmentDraftBloc, EnrollmentDraftState>(
    'LoadDraftDetailRequested → [Saving, DetailLoaded]',
    setUp: () {
      when(() => getDetail(any())).thenAnswer((_) async => const Right(detail));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadDraftDetailRequested('e1')),
    expect: () => const [
      EnrollmentDraftSaving(),
      EnrollmentDraftDetailLoaded(detail),
    ],
  );

  blocTest<EnrollmentDraftBloc, EnrollmentDraftState>(
    'FinalizeDraftRequested succès → [Saving, FinalizedPendingSync]',
    setUp: () {
      when(
        () => finalize(
          enrollmentId: any(named: 'enrollmentId'),
          emitDocument: any(named: 'emitDocument'),
        ),
      ).thenAnswer((_) async => const Right(unit));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const FinalizeDraftRequested('e1')),
    expect: () => const [
      EnrollmentDraftSaving(),
      EnrollmentDraftFinalizedPendingSync('e1'),
    ],
  );

  blocTest<EnrollmentDraftBloc, EnrollmentDraftState>(
    'FinalizeDraftRequested introuvable → [Saving, Error]',
    setUp: () {
      when(
        () => finalize(
          enrollmentId: any(named: 'enrollmentId'),
          emitDocument: any(named: 'emitDocument'),
        ),
      ).thenAnswer((_) async => const Left(NotFoundFailure()));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const FinalizeDraftRequested('e1')),
    expect: () => const [
      EnrollmentDraftSaving(),
      EnrollmentDraftError('Brouillon introuvable en local.'),
    ],
  );
}
