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
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_pre_enrollment_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_reenrollment_candidate_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_reenrollment_dossier_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_address_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_guardians_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_identity_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_previous_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_target_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/seed_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/start_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';

class MockGetLocalEnrollmentDetailUseCase extends Mock
    implements GetLocalEnrollmentDetailUseCase {}

class MockStartDraftUseCase extends Mock implements StartDraftUseCase {}

class MockSeedDraftUseCase extends Mock implements SeedDraftUseCase {}

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

class MockSyncEnrollmentPullsUseCase extends Mock
    implements SyncEnrollmentPullsUseCase {}

class MockGetReenrollmentCandidateUseCase extends Mock
    implements GetReenrollmentCandidateUseCase {}

class MockProbeReenrollmentDossierUseCase extends Mock
    implements ProbeReenrollmentDossierUseCase {}

class MockGetPreEnrollmentUseCase extends Mock
    implements GetPreEnrollmentUseCase {}

void main() {
  late MockGetLocalEnrollmentDetailUseCase getDetail;
  late MockStartDraftUseCase startDraft;
  late MockSeedDraftUseCase seedDraft;
  late MockSaveDraftIdentityUseCase saveIdentity;
  late MockSaveDraftAddressUseCase saveAddress;
  late MockSaveDraftPreviousAcademicUseCase savePreviousAcademic;
  late MockSaveDraftTargetAcademicUseCase saveTargetAcademic;
  late MockSaveDraftGuardiansUseCase saveGuardians;
  late MockGetDraftDetailUseCase getDraftDetail;
  late MockFinalizeDraftUseCase finalize;
  late MockSyncEnrollmentPullsUseCase syncPulls;
  late MockGetReenrollmentCandidateUseCase getReenrollmentCandidate;
  late MockProbeReenrollmentDossierUseCase probeReenrollment;
  late MockGetPreEnrollmentUseCase getPreEnrollment;

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

  const seed = ConfirmEnrollmentDraft(
    studentId: 's1',
    firstName: 'Amina',
    lastName: 'Moke',
    gender: 'FEMALE',
    dateOfBirth: '2015-04-02',
    enrollmentType: 'RE_ENROLLMENT',
    status: 'IN_PROGRESS',
    sourceRef: 'KIN-2025-0001',
    academicYearId: 'ay-2026',
    enrollmentDate: '2026-07-08',
  );

  setUpAll(() {
    registerFallbackValue(seed);
  });

  setUp(() {
    getDetail = MockGetLocalEnrollmentDetailUseCase();
    startDraft = MockStartDraftUseCase();
    seedDraft = MockSeedDraftUseCase();
    saveIdentity = MockSaveDraftIdentityUseCase();
    saveAddress = MockSaveDraftAddressUseCase();
    savePreviousAcademic = MockSaveDraftPreviousAcademicUseCase();
    saveTargetAcademic = MockSaveDraftTargetAcademicUseCase();
    saveGuardians = MockSaveDraftGuardiansUseCase();
    getDraftDetail = MockGetDraftDetailUseCase();
    finalize = MockFinalizeDraftUseCase();
    syncPulls = MockSyncEnrollmentPullsUseCase();
    getReenrollmentCandidate = MockGetReenrollmentCandidateUseCase();
    probeReenrollment = MockProbeReenrollmentDossierUseCase();
    getPreEnrollment = MockGetPreEnrollmentUseCase();
    // Défaut : aucun dossier existant → la sonde au tap laisse passer le seed.
    when(
      () => probeReenrollment(
        studentId: any(named: 'studentId'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => const Right(null));
    // Défaut PRE : aucun dossier local pour ce preEnrollmentId → la sonde au
    // tap (_getDetail) laisse passer le seed.
    when(
      () => getDetail(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));
  });

  EnrollmentOfflineBloc buildBloc() => EnrollmentOfflineBloc(
    getDetail: getDetail,
    startDraft: startDraft,
    seedDraft: seedDraft,
    saveIdentity: saveIdentity,
    saveAddress: saveAddress,
    savePreviousAcademic: savePreviousAcademic,
    saveTargetAcademic: saveTargetAcademic,
    saveGuardians: saveGuardians,
    getDraftDetail: getDraftDetail,
    finalize: finalize,
    syncPulls: syncPulls,
    getReenrollmentCandidate: getReenrollmentCandidate,
    probeReenrollment: probeReenrollment,
    getPreEnrollment: getPreEnrollment,
  );

  group('brouillon par étape (wizard)', () {
    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
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

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
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

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
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

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'LoadDraftDetailRequested → [Saving, DetailLoaded]',
      setUp: () {
        when(
          () => getDraftDetail(any()),
        ).thenAnswer((_) async => const Right(detail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDraftDetailRequested('e1')),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentDraftDetailLoaded(detail),
      ],
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
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

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'FinalizeDraftRequested introuvable → [Saving, FinalizeError]',
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
        EnrollmentDraftFinalizeError('Dossier introuvable en local.'),
      ],
    );
  });

  group('seed du brouillon (RE/PRE)', () {
    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedDraftRequested succès → [Saving, Started(ids), DetailLoaded]',
      setUp: () {
        when(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        ).thenAnswer(
          (_) async =>
              const Right(DraftIds(enrollmentId: 'e1', studentId: 's1')),
        );
        when(
          () => getDraftDetail(any()),
        ).thenAnswer((_) async => const Right(detail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SeedDraftRequested(seed)),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentDraftStarted('e1', 's1'),
        EnrollmentDraftDetailLoaded(detail),
      ],
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedDraftRequested conserve l\'enrollmentId serveur fourni',
      setUp: () {
        when(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        ).thenAnswer(
          (_) async =>
              const Right(DraftIds(enrollmentId: 'e-server', studentId: 's1')),
        );
        when(
          () => getDraftDetail(any()),
        ).thenAnswer((_) async => const Right(detail));
      },
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const SeedDraftRequested(seed, enrollmentId: 'e-server')),
      verify: (_) {
        verify(() => seedDraft(any(), enrollmentId: 'e-server')).called(1);
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedDraftRequested sur dossier déjà confirmé → [Saving, Error]',
      setUp: () {
        when(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        ).thenAnswer((_) async => const Left(ValidationFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SeedDraftRequested(seed)),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentDraftError('Brouillon déjà confirmé.'),
      ],
    );
  });

  group('seed depuis le local (RE cohorte / PRE préinscriptions)', () {
    const candidate = ReenrollmentCandidate(
      studentId: 's1',
      matriculationNumber: 'KIN-2025-0001',
      firstName: 'Amina',
      lastName: 'Moke',
      gender: 'FEMALE',
      dateOfBirth: '2015-04-02',
      guardianName: 'Jean Moke',
      guardianPhone: '+243900000000',
    );
    const pre = PreEnrollmentCandidate(
      id: 'pre-1',
      firstName: 'Amina',
      lastName: 'Moke',
      gender: 'FEMALE',
      dateOfBirth: '2015-04-02',
      desiredSchoolLevelId: 'lvl-1',
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromCohortRequested succès → lit la cohorte, seede un NOUVEAU '
      'dossier (enrollmentId null), matricule→sourceRef, tuteur projeté',
      setUp: () {
        when(
          () => getReenrollmentCandidate(any()),
        ).thenAnswer((_) async => const Right(candidate));
        when(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        ).thenAnswer(
          (_) async =>
              const Right(DraftIds(enrollmentId: 'e1', studentId: 's1')),
        );
        when(
          () => getDraftDetail(any()),
        ).thenAnswer((_) async => const Right(detail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromCohortRequested(
          studentId: 's1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentDraftStarted('e1', 's1'),
        EnrollmentDraftDetailLoaded(detail),
      ],
      verify: (_) {
        verify(() => getReenrollmentCandidate('s1')).called(1);
        final captured = verify(
          () => seedDraft(
            captureAny(),
            enrollmentId: captureAny(named: 'enrollmentId'),
          ),
        ).captured;
        final seedArg = captured[0] as ConfirmEnrollmentDraft;
        expect(captured[1], isNull); // RE : nouveau dossier N → uuid client
        expect(seedArg.enrollmentType, 'RE_ENROLLMENT');
        expect(seedArg.status, 'IN_PROGRESS');
        expect(seedArg.matriculationNumber, 'KIN-2025-0001');
        expect(seedArg.sourceRef, 'KIN-2025-0001');
        expect(seedArg.academicYearId, 'ay-2026');
        expect(seedArg.studentId, 's1'); // élève canonique conservé
        expect(seedArg.parents.length, 1);
        expect(seedArg.parents.first.phoneNumber, '+243900000000');
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromCohortRequested cohorte non peuplée → [Saving, Error], pas de seed',
      setUp: () {
        when(
          () => getReenrollmentCandidate(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure('cohorte vide')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromCohortRequested(
          studentId: 's1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentDraftError('Dossier introuvable en local.'),
      ],
      verify: (_) {
        verifyNever(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        );
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromCohortRequested : sonde trouve un DRAFT → Existing (reprise), '
      'jamais de seed ni de lecture cohorte',
      setUp: () {
        when(
          () => probeReenrollment(
            studentId: any(named: 'studentId'),
            academicYearId: any(named: 'academicYearId'),
          ),
        ).thenAnswer(
          (_) async => const Right(
            LocalDossierRef(
              enrollmentId: 'e-draft',
              syncState: SyncState.draft,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromCohortRequested(
          studentId: 's1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentLocalDossierExisting('e-draft', SyncState.draft),
      ],
      verify: (_) {
        verifyNever(() => getReenrollmentCandidate(any()));
        verifyNever(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        );
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromCohortRequested : sonde en ERREUR → traitée comme « aucun dossier » '
      '→ seed (le backstop de seedDraft protège encore)',
      setUp: () {
        when(
          () => probeReenrollment(
            studentId: any(named: 'studentId'),
            academicYearId: any(named: 'academicYearId'),
          ),
        ).thenAnswer((_) async => const Left(StorageFailure()));
        when(
          () => getReenrollmentCandidate(any()),
        ).thenAnswer((_) async => const Right(candidate));
        when(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        ).thenAnswer(
          (_) async =>
              const Right(DraftIds(enrollmentId: 'e1', studentId: 's1')),
        );
        when(
          () => getDraftDetail(any()),
        ).thenAnswer((_) async => const Right(detail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromCohortRequested(
          studentId: 's1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentDraftStarted('e1', 's1'),
        EnrollmentDraftDetailLoaded(detail),
      ],
      verify: (_) {
        verify(() => getReenrollmentCandidate('s1')).called(1);
        verify(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        ).called(1);
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromCohortRequested : sonde trouve un FINALISÉ → Existing (lecture '
      'seule), jamais de seed',
      setUp: () {
        when(
          () => probeReenrollment(
            studentId: any(named: 'studentId'),
            academicYearId: any(named: 'academicYearId'),
          ),
        ).thenAnswer(
          (_) async => const Right(
            LocalDossierRef(
              enrollmentId: 'e-sync',
              syncState: SyncState.pendingSync,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromCohortRequested(
          studentId: 's1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentLocalDossierExisting('e-sync', SyncState.pendingSync),
      ],
      verify: (_) {
        verifyNever(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        );
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromPreEnrollmentRequested succès → conserve l\'id préinscription '
      '(enrollmentId=id, sourceRef=id), élève généré',
      setUp: () {
        when(
          () => getPreEnrollment(any()),
        ).thenAnswer((_) async => const Right(pre));
        when(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        ).thenAnswer(
          (_) async =>
              const Right(DraftIds(enrollmentId: 'pre-1', studentId: 's9')),
        );
        when(
          () => getDraftDetail(any()),
        ).thenAnswer((_) async => const Right(detail));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromPreEnrollmentRequested(
          preEnrollmentId: 'pre-1',
          academicYearId: 'ay-2026',
        ),
      ),
      verify: (_) {
        verify(() => getPreEnrollment('pre-1')).called(1);
        final captured = verify(
          () => seedDraft(
            captureAny(),
            enrollmentId: captureAny(named: 'enrollmentId'),
          ),
        ).captured;
        final seedArg = captured[0] as ConfirmEnrollmentDraft;
        expect(captured[1], 'pre-1'); // PRE : id préinscription conservé
        expect(seedArg.enrollmentType, 'PRE_ENROLLMENT');
        expect(seedArg.sourceRef, 'pre-1');
        expect(seedArg.studentId, isNull); // élève créé au seed (uuid client)
        expect(seedArg.schoolLevelId, 'lvl-1');
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromPreEnrollmentRequested : sonde trouve un DRAFT (déjà seedé) → '
      'Existing (reprise), jamais de re-seed ni de lecture snapshot',
      setUp: () {
        when(
          () => getDetail('pre-1'),
        ).thenAnswer((_) async => const Right(detail)); // id='e1', DRAFT
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromPreEnrollmentRequested(
          preEnrollmentId: 'pre-1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentLocalDossierExisting('e1', SyncState.draft),
      ],
      verify: (_) {
        verifyNever(() => getPreEnrollment(any()));
        verifyNever(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        );
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromPreEnrollmentRequested : sonde trouve un FINALISÉ → Existing '
      '(lecture seule), jamais de re-seed',
      setUp: () {
        when(() => getDetail('pre-1')).thenAnswer(
          (_) async => const Right(
            LocalEnrollmentDetail(
              enrollment: LocalEnrollment(
                id: 'pre-1',
                studentId: 's9',
                enrollmentType: EnrollmentType.preEnrollment,
                status: OfflineEnrollmentStatus.completed,
                academicYearId: 'ay-2026',
                enrollmentDate: '2026-07-06',
                syncState: SyncState.pendingSync,
              ),
              student: LocalStudent(
                id: 's9',
                firstName: 'Amina',
                lastName: 'Moke',
                gender: OfflineGender.female,
                dateOfBirth: '2015-04-02',
                syncState: SyncState.pendingSync,
              ),
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromPreEnrollmentRequested(
          preEnrollmentId: 'pre-1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentLocalDossierExisting('pre-1', SyncState.pendingSync),
      ],
      verify: (_) {
        verifyNever(() => getPreEnrollment(any()));
        verifyNever(
          () => seedDraft(any(), enrollmentId: any(named: 'enrollmentId')),
        );
      },
    );

    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'SeedFromPreEnrollmentRequested snapshot non peuplé → [Saving, Error]',
      setUp: () {
        when(
          () => getPreEnrollment(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure('snapshot vide')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SeedFromPreEnrollmentRequested(
          preEnrollmentId: 'pre-1',
          academicYearId: 'ay-2026',
        ),
      ),
      expect: () => const [
        EnrollmentDraftSaving(),
        EnrollmentDraftError('Dossier introuvable en local.'),
      ],
    );
  });

  group('pull des ressources de référence', () {
    blocTest<EnrollmentOfflineBloc, EnrollmentOfflineState>(
      'EnrollmentPullRequested : silencieux (aucun état), délègue au usecase',
      setUp: () {
        when(() => syncPulls()).thenAnswer(
          (_) async => const EnrollmentPullsReport(
            updated: 2,
            notModified: 2,
            failed: 0,
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const EnrollmentPullRequested()),
      expect: () => const <EnrollmentOfflineState>[],
      verify: (_) {
        verify(() => syncPulls()).called(1);
      },
    );
  });
}
