import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
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
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';

class _MockGetLocalDetail extends Mock
    implements GetLocalEnrollmentDetailUseCase {}

class _MockStartDraft extends Mock implements StartDraftUseCase {}

class _MockSeedDraft extends Mock implements SeedDraftUseCase {}

class _MockSaveIdentity extends Mock implements SaveDraftIdentityUseCase {}

class _MockSaveAddress extends Mock implements SaveDraftAddressUseCase {}

class _MockSavePreviousAcademic extends Mock
    implements SaveDraftPreviousAcademicUseCase {}

class _MockSaveTargetAcademic extends Mock
    implements SaveDraftTargetAcademicUseCase {}

class _MockSaveGuardians extends Mock implements SaveDraftGuardiansUseCase {}

class _MockGetDraftDetail extends Mock implements GetDraftDetailUseCase {}

class _MockFinalize extends Mock implements FinalizeDraftUseCase {}

class _MockSyncPulls extends Mock implements SyncEnrollmentPullsUseCase {}

class _MockGetReenrollmentCandidate extends Mock
    implements GetReenrollmentCandidateUseCase {}

class _MockProbeReenrollment extends Mock
    implements ProbeReenrollmentDossierUseCase {}

class _MockGetPreEnrollment extends Mock implements GetPreEnrollmentUseCase {}

/// Session de correction d'un dossier **déjà complété**.
///
/// La ré-ouverture (`SYNCED|SYNC_ERROR → DRAFT`) ne peut pas être un événement
/// à part : deux événements courraient l'un contre l'autre sur le bloc, et une
/// ré-ouverture qui réussit devant une écriture qui échoue laisserait un
/// dossier déclassé sans la moindre correction pour le justifier. Elle voyage
/// donc AVEC l'écriture, jusque dans sa transaction — ce que ces tests
/// épinglent au seul endroit où c'est observable : l'argument passé au cas
/// d'usage.
void main() {
  late _MockSaveAddress saveAddress;
  late _MockSaveGuardians saveGuardians;
  late _MockFinalize finalize;

  setUp(() {
    saveAddress = _MockSaveAddress();
    saveGuardians = _MockSaveGuardians();
    finalize = _MockFinalize();
    when(
      () => saveAddress(
        studentId: any(named: 'studentId'),
        city: any(named: 'city'),
        district: any(named: 'district'),
        municipality: any(named: 'municipality'),
        neighborhood: any(named: 'neighborhood'),
        address: any(named: 'address'),
        reopenEnrollmentId: any(named: 'reopenEnrollmentId'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => saveGuardians(
        studentId: any(named: 'studentId'),
        parents: any(named: 'parents'),
        reopenEnrollmentId: any(named: 'reopenEnrollmentId'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => finalize(
        enrollmentId: any(named: 'enrollmentId'),
        emitDocument: any(named: 'emitDocument'),
        finalStatus: any(named: 'finalStatus'),
      ),
    ).thenAnswer((_) async => const Right(unit));
  });

  EnrollmentOfflineBloc buildBloc() => EnrollmentOfflineBloc(
    getDetail: _MockGetLocalDetail(),
    startDraft: _MockStartDraft(),
    seedDraft: _MockSeedDraft(),
    saveIdentity: _MockSaveIdentity(),
    saveAddress: saveAddress,
    savePreviousAcademic: _MockSavePreviousAcademic(),
    saveTargetAcademic: _MockSaveTargetAcademic(),
    saveGuardians: saveGuardians,
    getDraftDetail: _MockGetDraftDetail(),
    finalize: finalize,
    syncPulls: _MockSyncPulls(),
    getReenrollmentCandidate: _MockGetReenrollmentCandidate(),
    probeReenrollment: _MockProbeReenrollment(),
    getPreEnrollment: _MockGetPreEnrollment(),
  );

  String? capturedReopenIdOnAddress() =>
      verify(
            () => saveAddress(
              studentId: any(named: 'studentId'),
              city: any(named: 'city'),
              district: any(named: 'district'),
              municipality: any(named: 'municipality'),
              neighborhood: any(named: 'neighborhood'),
              address: any(named: 'address'),
              reopenEnrollmentId: captureAny(named: 'reopenEnrollmentId'),
            ),
          ).captured.single
          as String?;

  blocTest<EnrollmentOfflineBloc, dynamic>(
    'hors correction, aucune sauvegarde ne ré-ouvre quoi que ce soit',
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SaveDraftAddressRequested(studentId: 's1', city: 'Kin')),
    verify: (_) => expect(capturedReopenIdOnAddress(), isNull),
  );

  blocTest<EnrollmentOfflineBloc, dynamic>(
    'session armée : la sauvegarde d\'étape emporte la ré-ouverture',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const ReeditionSessionStarted('e1'));
      bloc.add(const SaveDraftAddressRequested(studentId: 's1', city: 'Kin'));
    },
    verify: (_) => expect(capturedReopenIdOnAddress(), 'e1'),
  );

  blocTest<EnrollmentOfflineBloc, dynamic>(
    'toutes les étapes l\'emportent, pas seulement la première rencontrée',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const ReeditionSessionStarted('e1'));
      bloc.add(const SaveDraftGuardiansRequested(studentId: 's1', parents: []));
    },
    verify: (_) {
      final captured =
          verify(
                () => saveGuardians(
                  studentId: any(named: 'studentId'),
                  parents: any(named: 'parents'),
                  reopenEnrollmentId: captureAny(named: 'reopenEnrollmentId'),
                ),
              ).captured.single
              as String?;
      expect(captured, 'e1');
    },
  );

  blocTest<EnrollmentOfflineBloc, dynamic>(
    'la session se referme à la finalisation : un dossier remis dans la file '
    'ne doit plus être ré-ouvert',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ReeditionSessionStarted('e1'));
      bloc.add(const FinalizeDraftRequested('e1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SaveDraftAddressRequested(studentId: 's1', city: 'Kin'));
    },
    verify: (_) => expect(capturedReopenIdOnAddress(), isNull),
  );

  blocTest<EnrollmentOfflineBloc, dynamic>(
    'une finalisation en ÉCHEC garde la session : le dossier est encore en '
    'brouillon, la correction suivante doit toujours pouvoir écrire',
    build: () {
      when(
        () => finalize(
          enrollmentId: any(named: 'enrollmentId'),
          emitDocument: any(named: 'emitDocument'),
          finalStatus: any(named: 'finalStatus'),
        ),
      ).thenAnswer((_) async => const Left(StorageFailure('boom')));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const ReeditionSessionStarted('e1'));
      bloc.add(const FinalizeDraftRequested('e1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SaveDraftAddressRequested(studentId: 's1', city: 'Kin'));
    },
    verify: (_) => expect(capturedReopenIdOnAddress(), 'e1'),
  );
}
