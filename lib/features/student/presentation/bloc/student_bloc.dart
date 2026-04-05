import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_personal_info_use_case.dart';

part 'student_event.dart';
part 'student_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final UpdateStudentPersonalInfoUseCase _updatePersonalInfoUseCase;

  StudentBloc({
    required UpdateStudentPersonalInfoUseCase updatePersonalInfoUseCase,
  })  : _updatePersonalInfoUseCase = updatePersonalInfoUseCase,
        super(const StudentState.initial()) {
    on<StudentPersonalInfoUpdateRequested>(_onPersonalInfoUpdateRequested);
    on<StudentStateReset>(_onStateReset);
  }

  FutureOr<void> _onStateReset(
    StudentStateReset event,
    Emitter<StudentState> emit,
  ) {
    emit(const StudentState.initial());
  }

  Future<void> _onPersonalInfoUpdateRequested(
    StudentPersonalInfoUpdateRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(state.copyWith(status: StudentUpdateStatus.loading, errorMessage: null));

    final result = await _updatePersonalInfoUseCase(
      studentId: event.studentId,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      dateOfBirth: event.dateOfBirth,
      gender: event.gender,
      birthPlace: event.birthPlace,
      nationality: event.nationality,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StudentUpdateStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (updatedStudent) => emit(
        state.copyWith(
          status: StudentUpdateStatus.success,
          updatedStudent: updatedStudent,
          errorMessage: null,
        ),
      ),
    );
  }
}
