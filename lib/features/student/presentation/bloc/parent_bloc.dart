import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/usecases/create_parent_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/unlink_parent_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_parent_use_case.dart';

part 'parent_event.dart';
part 'parent_state.dart';

class ParentBloc extends Bloc<ParentEvent, ParentState> {
  final UpdateParentUseCase _updateParentUseCase;
  final CreateParentUseCase _createParentUseCase;
  final UnlinkParentUseCase _unlinkParentUseCase;

  ParentBloc({
    required UpdateParentUseCase updateParentUseCase,
    required CreateParentUseCase createParentUseCase,
    required UnlinkParentUseCase unlinkParentUseCase,
  })  : _updateParentUseCase = updateParentUseCase,
        _createParentUseCase = createParentUseCase,
        _unlinkParentUseCase = unlinkParentUseCase,
        super(const ParentState.initial()) {
    on<ParentUpdateRequested>(_onParentUpdateRequested);
    on<ParentCreateRequested>(_onParentCreateRequested);
    on<ParentUnlinkRequested>(_onParentUnlinkRequested);
    on<ParentStateReset>(_onStateReset);
  }

  FutureOr<void> _onStateReset(
    ParentStateReset event,
    Emitter<ParentState> emit,
  ) {
    emit(const ParentState.initial());
  }

  Future<void> _onParentUpdateRequested(
    ParentUpdateRequested event,
    Emitter<ParentState> emit,
  ) async {
    emit(state.copyWith(
      status: ParentUpdateStatus.loading,
      operation: ParentOperation.update,
      errorMessage: null,
    ));

    final result = await _updateParentUseCase(
      parentId: event.parentId,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      email: event.email,
      phoneNumber: event.phoneNumber,
      relationshipType: event.relationshipType,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ParentUpdateStatus.failure,
        errorMessage: failure.message,
      )),
      (updatedParent) => emit(state.copyWith(
        status: ParentUpdateStatus.success,
        updatedParent: updatedParent,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onParentCreateRequested(
    ParentCreateRequested event,
    Emitter<ParentState> emit,
  ) async {
    emit(state.copyWith(
      status: ParentUpdateStatus.loading,
      operation: ParentOperation.create,
      errorMessage: null,
    ));

    final result = await _createParentUseCase(
      studentId: event.studentId,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      email: event.email,
      phoneNumber: event.phoneNumber,
      relationshipType: event.relationshipType,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ParentUpdateStatus.failure,
        errorMessage: failure.message,
      )),
      (createdParent) => emit(state.copyWith(
        status: ParentUpdateStatus.success,
        updatedParent: createdParent,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onParentUnlinkRequested(
    ParentUnlinkRequested event,
    Emitter<ParentState> emit,
  ) async {
    emit(state.copyWith(
      status: ParentUpdateStatus.loading,
      operation: ParentOperation.unlink,
      errorMessage: null,
    ));

    final result = await _unlinkParentUseCase(
      studentId: event.studentId,
      parentId: event.parentId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ParentUpdateStatus.unlinkFailure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: ParentUpdateStatus.unlinkSuccess,
        updatedParent: null,
        errorMessage: null,
      )),
    );
  }
}
