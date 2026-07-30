import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/record_classroom_transfer_draft.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/assign_enrollment_to_classroom_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_composed_rosters_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_unassigned_level_enrollments_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/record_classroom_transfer_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';

/// BLoC offline-first du module Classe : pull delta (CF2), lecture locale des
/// classes + roster composé (CF3), **transfert d'élève OFFLINE** (CF4, événement
/// + outbox) et affectation d'un non-réparti ONLINE (POST members, ADR-004).
///
/// État unique porteur (calque de [ClassroomBloc]) : les zones classes / roster
/// / transfert / affectation coexistent à l'écran. Le transfert émet un état
/// **pending-sync** (acquis en local) ; l'affectation exige la connexion.
class ClassroomOfflineBloc
    extends Bloc<ClassroomOfflineEvent, ClassroomOfflineState> {
  final SyncClassroomsUseCase _syncClassrooms;
  final GetOfflineClassroomsUseCase _getClassrooms;
  final GetOfflineRosterUseCase _getRoster;
  final GetComposedRostersUseCase _getComposedRosters;
  final GetUnassignedLevelEnrollmentsUseCase _getUnassignedEnrollments;
  final RecordClassroomTransferUseCase _recordTransfer;
  final AssignEnrollmentToClassroomUseCase _assignEnrollment;

  ClassroomOfflineBloc({
    required SyncClassroomsUseCase syncClassrooms,
    required GetOfflineClassroomsUseCase getClassrooms,
    required GetOfflineRosterUseCase getRoster,
    required GetComposedRostersUseCase getComposedRosters,
    required GetUnassignedLevelEnrollmentsUseCase getUnassignedEnrollments,
    required RecordClassroomTransferUseCase recordTransfer,
    required AssignEnrollmentToClassroomUseCase assignEnrollment,
  }) : _syncClassrooms = syncClassrooms,
       _getClassrooms = getClassrooms,
       _getRoster = getRoster,
       _getComposedRosters = getComposedRosters,
       _getUnassignedEnrollments = getUnassignedEnrollments,
       _recordTransfer = recordTransfer,
       _assignEnrollment = assignEnrollment,
       super(const ClassroomOfflineState()) {
    on<ClassroomsSyncRequested>(_onSyncRequested);
    on<OfflineClassroomsRequested>(_onClassroomsRequested);
    on<OfflineLevelClassroomsRequested>(_onLevelClassroomsRequested);
    on<OfflineRosterRequested>(_onRosterRequested);
    on<OfflineLevelRostersRequested>(_onLevelRostersRequested);
    on<OfflineLevelUnassignedEnrollmentsRequested>(
      _onLevelUnassignedEnrollmentsRequested,
    );
    on<MemberTransferRequested>(_onTransferRequested);
    on<MemberAssignRequested>(_onAssignRequested);
  }

  Future<void> _onSyncRequested(
    ClassroomsSyncRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(state.copyWith(syncStatus: ClassroomStatus.loading));

    final result = await _syncClassrooms(academicYearId: event.academicYearId);

    result.fold(
      (_) => emit(state.copyWith(syncStatus: ClassroomStatus.failure)),
      (outcome) => emit(
        state.copyWith(
          syncStatus: ClassroomStatus.success,
          freshness: outcome.syncedAt,
        ),
      ),
    );
  }

  Future<void> _onClassroomsRequested(
    OfflineClassroomsRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(
      state.copyWith(
        classroomsStatus: ClassroomStatus.loading,
        classroomsErrorType: ClassroomErrorType.none,
      ),
    );

    final result = await _getClassrooms(academicYearId: event.academicYearId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          classroomsStatus: ClassroomStatus.failure,
          classroomsErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (classrooms) => emit(
        state.copyWith(
          classroomsStatus: ClassroomStatus.success,
          classrooms: classrooms,
          classroomsErrorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onLevelClassroomsRequested(
    OfflineLevelClassroomsRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(
      state.copyWith(
        levelClassroomsStatus: ClassroomStatus.loading,
        levelClassroomsErrorType: ClassroomErrorType.none,
      ),
    );

    final result = await _getClassrooms(
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          levelClassroomsStatus: ClassroomStatus.failure,
          levelClassroomsErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (classrooms) => emit(
        state.copyWith(
          levelClassroomsStatus: ClassroomStatus.success,
          levelClassrooms: classrooms,
          levelClassroomsErrorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onRosterRequested(
    OfflineRosterRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(
      state.copyWith(
        rosterStatus: ClassroomStatus.loading,
        rosterErrorType: ClassroomErrorType.none,
      ),
    );

    final result = await _getRoster(
      classroomId: event.classroomId,
      query: event.query,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          rosterStatus: ClassroomStatus.failure,
          rosterErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (roster) => emit(
        state.copyWith(
          rosterStatus: ClassroomStatus.success,
          roster: roster,
          rosterErrorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onLevelRostersRequested(
    OfflineLevelRostersRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(state.copyWith(levelRostersStatus: ClassroomStatus.loading));

    final result = await _getComposedRosters(
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
    );

    result.fold(
      (_) => emit(state.copyWith(levelRostersStatus: ClassroomStatus.failure)),
      (rosters) => emit(
        state.copyWith(
          levelRostersStatus: ClassroomStatus.success,
          levelRosters: rosters,
        ),
      ),
    );
  }

  Future<void> _onLevelUnassignedEnrollmentsRequested(
    OfflineLevelUnassignedEnrollmentsRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(
      state.copyWith(
        levelUnassignedStatus: ClassroomStatus.loading,
        levelUnassignedErrorType: ClassroomErrorType.none,
      ),
    );

    final result = await _getUnassignedEnrollments(
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
    );

    result.fold(
      // Purge la liste : un échec ne doit jamais laisser afficher l'effectif
      // (périmé, potentiellement du niveau précédent) comme si de rien
      // n'était (cf. EnrollmentLocalListBloc._load, même principe).
      (failure) => emit(
        state.copyWith(
          levelUnassignedStatus: ClassroomStatus.failure,
          levelUnassignedEnrollments: const [],
          levelUnassignedErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (unassigned) => emit(
        state.copyWith(
          levelUnassignedStatus: ClassroomStatus.success,
          levelUnassignedEnrollments: unassigned,
          levelUnassignedErrorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onTransferRequested(
    MemberTransferRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(
      state.copyWith(
        transferStatus: ClassroomStatus.loading,
        transferErrorType: ClassroomErrorType.none,
        transferringStudentId: event.studentId,
        transferPendingSync: false,
      ),
    );

    final result = await _recordTransfer(
      RecordClassroomTransferDraft(
        studentId: event.studentId,
        fromClassroomId: event.fromClassroomId,
        toClassroomId: event.toClassroomId,
        schoolLevelId: event.schoolLevelId,
        academicYearId: event.academicYearId,
        reason: event.reason,
      ),
    );

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          transferStatus: ClassroomStatus.failure,
          transferErrorType: _mapFailureToErrorType(failure),
          transferringStudentId: '',
        ),
      ),
      // Événement enfilé (flush opportuniste déclenché par le repository) : le
      // transfert est acquis en local, « en attente de synchro ». On recharge
      // aussitôt les rosters composés du niveau → affichage optimiste en place.
      (_) async {
        emit(
          state.copyWith(
            transferStatus: ClassroomStatus.success,
            transferErrorType: ClassroomErrorType.none,
            transferringStudentId: '',
            transferPendingSync: true,
          ),
        );
        final rosters = await _getComposedRosters(
          academicYearId: event.academicYearId,
          schoolLevelId: event.schoolLevelId,
        );
        rosters.fold(
          (_) {},
          (map) => emit(
            state.copyWith(
              levelRostersStatus: ClassroomStatus.success,
              levelRosters: map,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onAssignRequested(
    MemberAssignRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(
      state.copyWith(
        assignStatus: ClassroomStatus.loading,
        assignErrorType: ClassroomErrorType.none,
        assigningEnrollmentId: event.enrollmentId,
        assignRePullFailed: false,
      ),
    );

    final result = await _assignEnrollment(
      classroomId: event.targetClassroomId,
      enrollmentId: event.enrollmentId,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          assignStatus: ClassroomStatus.failure,
          assignErrorType: _mapFailureToErrorType(failure),
          assigningEnrollmentId: '',
        ),
      ),
      // Right(true) → affectation + miroir à jour ; Right(false) → affectation
      // serveur acquise, miroir local KO (succès partiel à retenter, PAS un
      // échec).
      (mirrorOk) => emit(
        state.copyWith(
          assignStatus: ClassroomStatus.success,
          assignErrorType: ClassroomErrorType.none,
          assigningEnrollmentId: '',
          assignRePullFailed: !mirrorOk,
        ),
      ),
    );
  }

  ClassroomErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => ClassroomErrorType.network,
        NotFoundFailure() => ClassroomErrorType.notFound,
        ValidationFailure() => ClassroomErrorType.validation,
        UnauthorizedFailure() => ClassroomErrorType.unauthorized,
        InvalidCredentialsFailure() => ClassroomErrorType.invalidCredentials,
        ServerFailure() => ClassroomErrorType.server,
        StorageFailure() => ClassroomErrorType.storage,
        AuthFailure() => ClassroomErrorType.auth,
        _ => ClassroomErrorType.unknown,
      };
}
