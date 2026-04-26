import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/get_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';

class ClassroomBloc extends Bloc<ClassroomEvent, ClassroomState> {
  final GetClassroomsUseCase _getClassroomsUseCase;

  ClassroomBloc({required GetClassroomsUseCase getClassroomsUseCase})
    : _getClassroomsUseCase = getClassroomsUseCase,
      super(const ClassroomState()) {
    on<ClassroomRequested>(_onClassroomRequested);
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
