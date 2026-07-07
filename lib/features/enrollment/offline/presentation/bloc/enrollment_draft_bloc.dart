import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/finalize_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_draft_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_address_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_guardians_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_identity_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_previous_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_target_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/start_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_state.dart';

/// BLoC du wizard d'inscription offline-first : chaque étape persiste un
/// brouillon local (DRAFT) ; la confirmation bascule en PENDING_SYNC.
class EnrollmentDraftBloc
    extends Bloc<EnrollmentDraftEvent, EnrollmentDraftState> {
  final StartDraftUseCase _startDraft;
  final SaveDraftIdentityUseCase _saveIdentity;
  final SaveDraftAddressUseCase _saveAddress;
  final SaveDraftPreviousAcademicUseCase _savePreviousAcademic;
  final SaveDraftTargetAcademicUseCase _saveTargetAcademic;
  final SaveDraftGuardiansUseCase _saveGuardians;
  final GetDraftDetailUseCase _getDetail;
  final FinalizeDraftUseCase _finalize;

  EnrollmentDraftBloc({
    required StartDraftUseCase startDraft,
    required SaveDraftIdentityUseCase saveIdentity,
    required SaveDraftAddressUseCase saveAddress,
    required SaveDraftPreviousAcademicUseCase savePreviousAcademic,
    required SaveDraftTargetAcademicUseCase saveTargetAcademic,
    required SaveDraftGuardiansUseCase saveGuardians,
    required GetDraftDetailUseCase getDetail,
    required FinalizeDraftUseCase finalize,
  }) : _startDraft = startDraft,
       _saveIdentity = saveIdentity,
       _saveAddress = saveAddress,
       _savePreviousAcademic = savePreviousAcademic,
       _saveTargetAcademic = saveTargetAcademic,
       _saveGuardians = saveGuardians,
       _getDetail = getDetail,
       _finalize = finalize,
       super(const EnrollmentDraftInitial()) {
    on<StartDraftRequested>(_onStart);
    on<SaveDraftIdentityRequested>(_onSaveIdentity);
    on<SaveDraftAddressRequested>(_onSaveAddress);
    on<SaveDraftPreviousAcademicRequested>(_onSavePreviousAcademic);
    on<SaveDraftTargetAcademicRequested>(_onSaveTargetAcademic);
    on<SaveDraftGuardiansRequested>(_onSaveGuardians);
    on<LoadDraftDetailRequested>(_onLoadDetail);
    on<FinalizeDraftRequested>(_onFinalize);
  }

  void _onStart(StartDraftRequested event, Emitter<EnrollmentDraftState> emit) {
    final ids = _startDraft(existingStudentId: event.existingStudentId);
    emit(EnrollmentDraftStarted(ids.enrollmentId, ids.studentId));
  }

  Future<void> _onSaveIdentity(
    SaveDraftIdentityRequested event,
    Emitter<EnrollmentDraftState> emit,
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
    Emitter<EnrollmentDraftState> emit,
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
    Emitter<EnrollmentDraftState> emit,
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
    Emitter<EnrollmentDraftState> emit,
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
    Emitter<EnrollmentDraftState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _saveGuardians(
      studentId: event.studentId,
      parents: event.parents,
    );
    _emitStep(result, emit);
  }

  Future<void> _onLoadDetail(
    LoadDraftDetailRequested event,
    Emitter<EnrollmentDraftState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _getDetail(event.enrollmentId);
    emit(
      result.fold(
        (f) => EnrollmentDraftError(_map(f)),
        (detail) => EnrollmentDraftDetailLoaded(detail),
      ),
    );
  }

  Future<void> _onFinalize(
    FinalizeDraftRequested event,
    Emitter<EnrollmentDraftState> emit,
  ) async {
    emit(const EnrollmentDraftSaving());
    final result = await _finalize(
      enrollmentId: event.enrollmentId,
      emitDocument: event.emitDocument,
    );
    emit(
      result.fold(
        (f) => EnrollmentDraftError(_map(f)),
        (_) => EnrollmentDraftFinalizedPendingSync(event.enrollmentId),
      ),
    );
  }

  void _emitStep<T>(
    Either<Failure, T> result,
    Emitter<EnrollmentDraftState> emit,
  ) {
    emit(
      result.fold(
        (f) => EnrollmentDraftError(_map(f)),
        (_) => const EnrollmentDraftStepSaved(),
      ),
    );
  }

  String _map(Failure failure) => switch (failure) {
    NotFoundFailure() => 'Brouillon introuvable en local.',
    ValidationFailure() => 'Brouillon déjà confirmé.',
    StorageFailure() => 'Erreur d\'accès à la base locale.',
    _ => 'Une erreur est survenue.',
  };
}
