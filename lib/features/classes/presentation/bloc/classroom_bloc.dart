import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/distribute_students_to_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classroom_members_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';

class ClassroomBloc extends Bloc<ClassroomEvent, ClassroomState> {
  final GetClassroomsUseCase _getClassroomsUseCase;
  final GetClassroomMembersUseCase _getClassroomMembersUseCase;
  final DistributeStudentsToClassroomsUseCase
  _distributeStudentsToClassroomsUseCase;

  ClassroomBloc({
    required GetClassroomsUseCase getClassroomsUseCase,
    required GetClassroomMembersUseCase getClassroomMembersUseCase,
    required DistributeStudentsToClassroomsUseCase
    distributeStudentsToClassroomsUseCase,
  }) : _getClassroomsUseCase = getClassroomsUseCase,
       _getClassroomMembersUseCase = getClassroomMembersUseCase,
       _distributeStudentsToClassroomsUseCase =
           distributeStudentsToClassroomsUseCase,
       super(const ClassroomState()) {
    on<ClassroomRequested>(_onClassroomRequested);
    on<ClassroomMembersRequested>(_onClassroomMembersRequested);
    on<ClassroomDistributionRequested>(_onClassroomDistributionRequested);
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

  Future<void> _onClassroomMembersRequested(
    ClassroomMembersRequested event,
    Emitter<ClassroomState> emit,
  ) async {
    emit(
      state.copyWith(
        membersStatus: ClassroomStatus.loading,
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
          membersErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (members) => emit(
        state.copyWith(
          membersStatus: ClassroomStatus.success,
          members: members,
          membersErrorType: ClassroomErrorType.none,
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
