import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/distribute_students_to_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_members_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_level_distribution_overview_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/reassign_classroom_member_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';

class ClassroomBloc extends Bloc<ClassroomEvent, ClassroomState> {
  final GetClassroomsUseCase _getClassroomsUseCase;
  final GetClassroomMembersUseCase _getClassroomMembersUseCase;
  final DistributeStudentsToClassroomsUseCase
  _distributeStudentsToClassroomsUseCase;
  final GetLevelDistributionOverviewUseCase
  _getLevelDistributionOverviewUseCase;
  final ReassignClassroomMemberUseCase _reassignClassroomMemberUseCase;

  ClassroomBloc({
    required GetClassroomsUseCase getClassroomsUseCase,
    required GetClassroomMembersUseCase getClassroomMembersUseCase,
    required DistributeStudentsToClassroomsUseCase
    distributeStudentsToClassroomsUseCase,
    required GetLevelDistributionOverviewUseCase
    getLevelDistributionOverviewUseCase,
    required ReassignClassroomMemberUseCase reassignClassroomMemberUseCase,
  }) : _getClassroomsUseCase = getClassroomsUseCase,
       _getClassroomMembersUseCase = getClassroomMembersUseCase,
       _distributeStudentsToClassroomsUseCase =
           distributeStudentsToClassroomsUseCase,
        _getLevelDistributionOverviewUseCase =
            getLevelDistributionOverviewUseCase,
       _reassignClassroomMemberUseCase = reassignClassroomMemberUseCase,
       super(const ClassroomState()) {
    on<ClassroomRequested>(_onClassroomRequested);
    on<ClassroomMembersRequested>(_onClassroomMembersRequested);
    on<ClassroomDistributionOverviewRequested>(
      _onClassroomDistributionOverviewRequested,
    );
    on<ClassroomMembersBatchRequested>(_onClassroomMembersBatchRequested);
    on<ClassroomDistributionRequested>(_onClassroomDistributionRequested);
    on<ClassroomMemberReassignRequested>(_onClassroomMemberReassignRequested);
    on<ClassroomResetRequested>(_onClassroomResetRequested);
  }

  Future<void> _onClassroomRequested(
    ClassroomRequested event,
    Emitter<ClassroomState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ClassroomStatus.loading,
        errorType: ClassroomErrorType.none,
      ),
    );

    final result = await _getClassroomsUseCase(
      schoolLevelGroupId: event.schoolLevelGroupId,
      schoolLevelId: event.schoolLevelId,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ClassroomStatus.failure,
          errorType: _mapFailureToErrorType(failure),
        ),
      ),
      (classrooms) => emit(
        state.copyWith(
          status: ClassroomStatus.success,
          classrooms: classrooms,
          errorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  void _onClassroomResetRequested(
    ClassroomResetRequested event,
    Emitter<ClassroomState> emit,
  ) {
    emit(const ClassroomState());
  }

  Future<void> _onClassroomDistributionRequested(
    ClassroomDistributionRequested event,
    Emitter<ClassroomState> emit,
  ) async {
    emit(
      state.copyWith(
        distributionStatus: ClassroomStatus.loading,
        distributionErrorType: ClassroomErrorType.none,
      ),
    );

    final result = await _distributeStudentsToClassroomsUseCase(
      academicYearId: event.academicYearId,
      schoolLevelGroupId: event.schoolLevelGroupId,
      schoolLevelId: event.schoolLevelId,
      distributionCriterion: event.distributionCriterion,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          distributionStatus: ClassroomStatus.failure,
          distributionErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (_) => emit(
        state.copyWith(
          distributionStatus: ClassroomStatus.success,
          distributionErrorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onClassroomDistributionOverviewRequested(
    ClassroomDistributionOverviewRequested event,
    Emitter<ClassroomState> emit,
  ) async {
    emit(
      state.copyWith(
        distributionOverviewStatus: ClassroomStatus.loading,
        distributionOverviewErrorType: ClassroomErrorType.none,
      ),
    );

    final result = await _getLevelDistributionOverviewUseCase(
      academicYearId: event.academicYearId,
      schoolLevelId: event.schoolLevelId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          distributionOverviewStatus: ClassroomStatus.failure,
          distributionOverviewErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (overview) => emit(
        state.copyWith(
          distributionOverviewStatus: ClassroomStatus.success,
          distributionOverview: overview,
          distributionOverviewErrorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onClassroomMembersRequested(
    ClassroomMembersRequested event,
    Emitter<ClassroomState> emit,
  ) async {
    emit(
      state.copyWith(
        membersStatus: ClassroomStatus.loading,
        membersLoadingCount: 1,
        membersErrorType: ClassroomErrorType.none,
      ),
    );

    final result = await _getClassroomMembersUseCase(
      classroomId: event.classroomId,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          membersStatus: ClassroomStatus.failure,
          membersLoadingCount: 0,
          membersErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (members) => emit(
        state.copyWith(
          membersStatus: ClassroomStatus.success,
          members: members,
          membersLoadingCount: 0,
          membersErrorType: ClassroomErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onClassroomMembersBatchRequested(
    ClassroomMembersBatchRequested event,
    Emitter<ClassroomState> emit,
  ) async {
    emit(
      state.copyWith(
        membersStatus: ClassroomStatus.loading,
        membersLoadingCount: event.classroomIds.length,
        membersErrorType: ClassroomErrorType.none,
        membersByClassroom: const [],
      ),
    );

    final results = await Future.wait(
      event.classroomIds.map(
        (classroomId) async {
          final result = await _getClassroomMembersUseCase(
            classroomId: classroomId,
            academicYearId: event.academicYearId,
          );
          return (classroomId: classroomId, result: result);
        },
      ),
    );

    final buckets = <ClassroomMembersGroup>[];
    for (final item in results) {
      final failed = item.result.fold<bool>(
        (failure) {
          emit(
            state.copyWith(
              membersStatus: ClassroomStatus.failure,
              membersLoadingCount: 0,
              membersErrorType: _mapFailureToErrorType(failure),
            ),
          );
          return true;
        },
        (members) {
          buckets.add(
            ClassroomMembersGroup(
              classroomId: item.classroomId,
              members: members,
            ),
          );
          return false;
        },
      );

      if (failed) {
        return;
      }
    }

    emit(
      state.copyWith(
        membersStatus: ClassroomStatus.success,
        membersByClassroom: buckets,
        membersLoadingCount: 0,
        membersErrorType: ClassroomErrorType.none,
      ),
    );
  }

  Future<void> _onClassroomMemberReassignRequested(
    ClassroomMemberReassignRequested event,
    Emitter<ClassroomState> emit,
  ) async {
    emit(
      state.copyWith(
        reassignStatus: ClassroomStatus.loading,
        reassignErrorType: ClassroomErrorType.none,
        reassigningMemberId: event.classroomMemberId,
      ),
    );

    final result = await _reassignClassroomMemberUseCase(
      classroomMemberId: event.classroomMemberId,
      targetClassroomId: event.targetClassroomId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          reassignStatus: ClassroomStatus.failure,
          reassignErrorType: _mapFailureToErrorType(failure),
          reassigningMemberId: '',
        ),
      ),
      (_) => emit(
        state.copyWith(
          reassignStatus: ClassroomStatus.success,
          reassignErrorType: ClassroomErrorType.none,
          reassigningMemberId: '',
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
