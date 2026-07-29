import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
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
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/enrollment_confirm_draft_builder.dart';

/// BLoC **unique** du wizard Inscription offline (convergence des anciens
/// EnrollmentOfflineBloc + EnrollmentDraftBloc) : lecture du détail local,
/// brouillon par étape du wizard (NEW, et RE/PRE via seed), finalisation (1
/// flush agrégat) et pull des ressources de référence.
///
/// Le LISTING (listes/recherches locales) est porté par `EnrollmentLocalListBloc`
/// (bloc dédié) — pas ici, pour éviter les collisions d'état avec le détail/brouillon.
class EnrollmentOfflineBloc
    extends Bloc<EnrollmentOfflineEvent, EnrollmentOfflineState> {
  final GetLocalEnrollmentDetailUseCase _getDetail;
  final StartDraftUseCase _startDraft;
  final SeedDraftUseCase _seedDraft;
  final GetReenrollmentCandidateUseCase _getReenrollmentCandidate;
  final ProbeReenrollmentDossierUseCase _probeReenrollment;
  final GetPreEnrollmentUseCase _getPreEnrollment;
  final SaveDraftIdentityUseCase _saveIdentity;
  final SaveDraftAddressUseCase _saveAddress;
  final SaveDraftPreviousAcademicUseCase _savePreviousAcademic;
  final SaveDraftTargetAcademicUseCase _saveTargetAcademic;
  final SaveDraftGuardiansUseCase _saveGuardians;
  final GetDraftDetailUseCase _getDraftDetail;
  final FinalizeDraftUseCase _finalize;
  final SyncEnrollmentPullsUseCase _syncPulls;

  EnrollmentOfflineBloc({
    required GetLocalEnrollmentDetailUseCase getDetail,
    required StartDraftUseCase startDraft,
    required SeedDraftUseCase seedDraft,
    required GetReenrollmentCandidateUseCase getReenrollmentCandidate,
    required ProbeReenrollmentDossierUseCase probeReenrollment,
    required GetPreEnrollmentUseCase getPreEnrollment,
    required SaveDraftIdentityUseCase saveIdentity,
    required SaveDraftAddressUseCase saveAddress,
    required SaveDraftPreviousAcademicUseCase savePreviousAcademic,
    required SaveDraftTargetAcademicUseCase saveTargetAcademic,
    required SaveDraftGuardiansUseCase saveGuardians,
    required GetDraftDetailUseCase getDraftDetail,
    required FinalizeDraftUseCase finalize,
    required SyncEnrollmentPullsUseCase syncPulls,
  }) : _getDetail = getDetail,
       _startDraft = startDraft,
       _seedDraft = seedDraft,
       _getReenrollmentCandidate = getReenrollmentCandidate,
       _probeReenrollment = probeReenrollment,
       _getPreEnrollment = getPreEnrollment,
       _saveIdentity = saveIdentity,
       _saveAddress = saveAddress,
       _savePreviousAcademic = savePreviousAcademic,
       _saveTargetAcademic = saveTargetAcademic,
       _saveGuardians = saveGuardians,
       _getDraftDetail = getDraftDetail,
       _finalize = finalize,
       _syncPulls = syncPulls,
       super(const EnrollmentOfflineInitial()) {
    on<LoadLocalEnrollmentDetail>(_onDetail);
    on<StartDraftRequested>(_onStartDraft);
    on<SeedDraftRequested>(_onSeedDraft);
    on<SeedFromCohortRequested>(_onSeedFromCohort);
    on<SeedFromPreEnrollmentRequested>(_onSeedFromPreEnrollment);
    on<SaveDraftIdentityRequested>(_onSaveIdentity);
    on<SaveDraftAddressRequested>(_onSaveAddress);
    on<SaveDraftPreviousAcademicRequested>(_onSavePreviousAcademic);
    on<SaveDraftTargetAcademicRequested>(_onSaveTargetAcademic);
    on<SaveDraftGuardiansRequested>(_onSaveGuardians);
    on<LoadDraftDetailRequested>(_onLoadDraftDetail);
    on<FinalizeDraftRequested>(_onFinalize);
    on<EnrollmentPullRequested>(_onPull);
  }

  // ── Lecture du détail local ─────────────────────────────────────────────────

  Future<void> _onDetail(
    LoadLocalEnrollmentDetail event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentOfflineLoading());
    final result = await _getDetail(event.enrollmentId);
    emit(
      result.fold(
        (f) => EnrollmentOfflineError(_map(f)),
        (detail) => EnrollmentOfflineDetailLoaded(detail),
      ),
    );
  }

  // ── Brouillon par étape (wizard) ────────────────────────────────────────────

  void _onStartDraft(
    StartDraftRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) {
    final ids = _startDraft(existingStudentId: event.existingStudentId);
    emit(EnrollmentDraftStarted(ids.enrollmentId, ids.studentId));
  }

  /// Seed RE/PRE/reprise : écrit la photo de départ puis relit le brouillon — la
  /// page reçoit les ids ([EnrollmentDraftStarted]) puis l'agrégat local
  /// ([EnrollmentDraftDetailLoaded]), comme après une écriture d'étape.
  Future<void> _onSeedDraft(
    SeedDraftRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    await _seedAndEmit(
      event.seed,
      enrollmentId: event.enrollmentId,
      emit: emit,
    );
  }

  /// Seed **RE depuis la cohorte N-1 locale** : lit le candidat par `studentId`,
  /// projette la photo de départ (matricule → `source_ref`), puis seede un
  /// **nouveau** dossier de l'année N (uuid client → `enrollmentId` null).
  /// Cohorte non peuplée → `NotFoundFailure` → état d'erreur (régression assumée
  /// tant que le pull dort).
  Future<void> _onSeedFromCohort(
    SeedFromCohortRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    // Sonde au tap : un dossier local existe-t-il DÉJÀ pour cet élève cette
    // année ? Si oui, on l'OUVRE (reprise DRAFT / lecture seule finalisé) au lieu
    // de seeder un doublon — robuste face à une liste périmée ou une année
    // divergente (au-delà de la dédup de la liste + du backstop dur du seed). Une
    // erreur de sonde (lecture locale) est ignorée → on retombe sur le seed
    // (que le backstop de `seedDraft` protège encore).
    final probe = await _probeReenrollment(
      studentId: event.studentId,
      academicYearId: event.academicYearId,
    );
    final existing = probe.getOrElse(() => null);
    if (existing != null) {
      emit(
        EnrollmentLocalDossierExisting(
          existing.enrollmentId,
          existing.syncState,
        ),
      );
      return;
    }

    final candidate = await _getReenrollmentCandidate(event.studentId);
    await candidate.fold((f) async => emit(EnrollmentDraftError(_map(f))), (
      c,
    ) async {
      final seed = EnrollmentConfirmDraftBuilder.fromReenrollmentCandidate(
        candidate: c,
        academicYearId: event.academicYearId,
      );
      await _seedAndEmit(seed, enrollmentId: null, emit: emit);
    });
  }

  /// Seed **PRE depuis le snapshot local** : lit la préinscription par `id`,
  /// projette la photo de départ, puis seede en conservant l'`id` comme
  /// enrollmentId (idempotence G2) et `source_ref`. Snapshot non peuplé →
  /// `NotFoundFailure` → état d'erreur.
  ///
  /// Sonde au tap AVANT de seeder : `preEnrollmentId` EST l'id déterministe du
  /// futur dossier (contrairement à RE, dont l'id est un uuid client généré à
  /// chaque seed) — un second tap sur le même candidat re-seederait par-dessus
  /// avec un `studentId` neuf (`seedDraft` en génère un si `null`),
  /// orphelinant les données déjà saisies. On ouvre le dossier existant au
  /// lieu de reseeder (reprise DRAFT / lecture seule finalisé — même état que
  /// la sonde RE, cf. [_onSeedFromCohort]).
  Future<void> _onSeedFromPreEnrollment(
    SeedFromPreEnrollmentRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final existing = await _getDetail(event.preEnrollmentId);
    final existingDetail = existing.fold((_) => null, (d) => d);
    if (existingDetail != null) {
      emit(
        EnrollmentLocalDossierExisting(
          existingDetail.enrollment.id,
          existingDetail.enrollment.syncState,
        ),
      );
      return;
    }

    final pre = await _getPreEnrollment(event.preEnrollmentId);
    await pre.fold((f) async => emit(EnrollmentDraftError(_map(f))), (p) async {
      final seed = EnrollmentConfirmDraftBuilder.fromPreEnrollment(
        pre: p,
        academicYearId: event.academicYearId,
      );
      await _seedAndEmit(seed, enrollmentId: p.id, emit: emit);
    });
  }

  /// Tail partagé du seed : écrit la photo → émet les ids → relit l'agrégat
  /// local. Suppose l'état `EnrollmentDraftSaving` déjà émis par l'appelant.
  Future<void> _seedAndEmit(
    ConfirmEnrollmentDraft seed, {
    required String? enrollmentId,
    required Emitter<EnrollmentOfflineState> emit,
  }) async {
    final seeded = await _seedDraft(seed, enrollmentId: enrollmentId);
    await seeded.fold((f) async => emit(EnrollmentDraftError(_map(f))), (
      ids,
    ) async {
      emit(EnrollmentDraftStarted(ids.enrollmentId, ids.studentId));
      final detail = await _getDraftDetail(ids.enrollmentId);
      emit(
        detail.fold(
          (f) => EnrollmentDraftError(_map(f)),
          (d) => EnrollmentDraftDetailLoaded(d),
        ),
      );
    });
  }

  Future<void> _onSaveIdentity(
    SaveDraftIdentityRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _saveIdentity(
      enrollmentId: event.enrollmentId,
      studentId: event.studentId,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      gender: event.gender,
      dateOfBirth: event.dateOfBirth,
      birthPlace: event.birthPlace,
      nationality: event.nationality,
      matriculationNumber: event.matriculationNumber,
      enrollmentType: event.enrollmentType,
      status: event.status,
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
      schoolLevelGroupId: event.schoolLevelGroupId,
      enrollmentDate: event.enrollmentDate,
    );
    _emitStep(result, emit);
  }

  Future<void> _onSaveAddress(
    SaveDraftAddressRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _saveAddress(
      studentId: event.studentId,
      city: event.city,
      district: event.district,
      municipality: event.municipality,
      neighborhood: event.neighborhood,
      address: event.address,
      phoneNumber: event.phoneNumber,
    );
    _emitStep(result, emit);
  }

  Future<void> _onSavePreviousAcademic(
    SaveDraftPreviousAcademicRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _savePreviousAcademic(
      enrollmentId: event.enrollmentId,
      previousSchoolName: event.previousSchoolName,
      previousAcademicYear: event.previousAcademicYear,
      previousSchoolLevelGroup: event.previousSchoolLevelGroup,
      previousSchoolLevel: event.previousSchoolLevel,
      previousRate: event.previousRate,
      previousRank: event.previousRank,
      validatedPreviousYear: event.validatedPreviousYear,
      transferReason: event.transferReason,
    );
    _emitStep(result, emit);
  }

  Future<void> _onSaveTargetAcademic(
    SaveDraftTargetAcademicRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _saveTargetAcademic(
      enrollmentId: event.enrollmentId,
      schoolLevelId: event.schoolLevelId,
      schoolLevelGroupId: event.schoolLevelGroupId,
    );
    _emitStep(result, emit);
  }

  Future<void> _onSaveGuardians(
    SaveDraftGuardiansRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _saveGuardians(
      studentId: event.studentId,
      parents: event.parents,
    );
    _emitStep(result, emit);
  }

  Future<void> _onLoadDraftDetail(
    LoadDraftDetailRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _getDraftDetail(event.enrollmentId);
    emit(
      result.fold(
        (f) => EnrollmentDraftError(_map(f)),
        (detail) => EnrollmentDraftDetailLoaded(detail),
      ),
    );
  }

  Future<void> _onFinalize(
    FinalizeDraftRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _finalize(
      enrollmentId: event.enrollmentId,
      emitDocument: event.emitDocument,
      finalStatus: event.finalStatus,
    );
    emit(
      result.fold(
        (f) => EnrollmentDraftFinalizeError(_map(f)),
        (_) => EnrollmentDraftFinalizedPendingSync(event.enrollmentId),
      ),
    );
  }

  // ── Pull des ressources de référence (silencieux, best-effort) ─────────────

  Future<void> _onPull(
    EnrollmentPullRequested event,
    Emitter<EnrollmentOfflineState> emit,
  ) async {
    await _syncPulls();
  }

  void _emitStep<T>(
    Either<Failure, T> result,
    Emitter<EnrollmentOfflineState> emit,
  ) {
    emit(
      result.fold(
        (f) => EnrollmentDraftError(_map(f)),
        (_) => const EnrollmentDraftStepSaved(),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    NotFoundFailure() => 'Dossier introuvable en local.',
    ValidationFailure() => 'Brouillon déjà confirmé.',
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    _ => 'Une erreur est survenue.',
  };
}
