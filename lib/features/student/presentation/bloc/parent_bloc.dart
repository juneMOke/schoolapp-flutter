import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_parent_use_case.dart';

part 'parent_event.dart';
part 'parent_state.dart';

class ParentBloc extends Bloc<ParentEvent, ParentState> {
  final UpdateParentUseCase _updateParentUseCase;

  ParentBloc({
    required UpdateParentUseCase updateParentUseCase,
  })  : _updateParentUseCase = updateParentUseCase,
        super(const ParentState.initial()) {
    on<ParentUpdateRequested>(_onParentUpdateRequested);
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
}
