import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/reassign_member_online_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/sync_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';

/// BLoC offline-first du module Classe : pull delta (CF2), lecture locale des
/// classes + roster (CF3) et déplacement d'élève ONLINE (CF4 Option A).
///
/// État unique porteur (calque de [ClassroomBloc]) : les zones classes / roster
/// / réassignation coexistent à l'écran. La réassignation N'A PAS d'état
/// pending-sync (elle exige la connexion). La fraîcheur est dérivée du
/// `syncedAt` du bilan de pull.
class ClassroomOfflineBloc
    extends Bloc<ClassroomOfflineEvent, ClassroomOfflineState> {
  final SyncClassroomsUseCase _syncClassrooms;
  final GetOfflineClassroomsUseCase _getClassrooms;
  final GetOfflineRosterUseCase _getRoster;
  final ReassignMemberOnlineUseCase _reassignMember;

  ClassroomOfflineBloc({
    required SyncClassroomsUseCase syncClassrooms,
    required GetOfflineClassroomsUseCase getClassrooms,
    required GetOfflineRosterUseCase getRoster,
    required ReassignMemberOnlineUseCase reassignMember,
  }) : _syncClassrooms = syncClassrooms,
       _getClassrooms = getClassrooms,
       _getRoster = getRoster,
       _reassignMember = reassignMember,
       super(const ClassroomOfflineState()) {
    on<ClassroomsSyncRequested>(_onSyncRequested);
    on<OfflineClassroomsRequested>(_onClassroomsRequested);
    on<OfflineRosterRequested>(_onRosterRequested);
    on<MemberReassignRequested>(_onReassignRequested);
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

    final result = await _getClassrooms(
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
    );

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

  Future<void> _onReassignRequested(
    MemberReassignRequested event,
    Emitter<ClassroomOfflineState> emit,
  ) async {
    emit(
      state.copyWith(
        reassignStatus: ClassroomStatus.loading,
        reassignErrorType: ClassroomErrorType.none,
        reassigningMemberId: event.classroomMemberId,
        reassignRePullFailed: false,
      ),
    );

    final result = await _reassignMember(
      classroomMemberId: event.classroomMemberId,
      targetClassroomId: event.targetClassroomId,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          reassignStatus: ClassroomStatus.failure,
          reassignErrorType: _mapFailureToErrorType(failure),
          reassigningMemberId: '',
        ),
      ),
      // Right(true) → déplacement + re-pull OK ; Right(false) → déplacement OK,
      // re-pull local KO (succès partiel à retenter, PAS un échec).
      (rePullOk) => emit(
        state.copyWith(
          reassignStatus: ClassroomStatus.success,
          reassignErrorType: ClassroomErrorType.none,
          reassigningMemberId: '',
          reassignRePullFailed: !rePullOk,
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
