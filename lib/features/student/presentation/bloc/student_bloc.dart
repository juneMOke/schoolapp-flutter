import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_academic_info.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_academic_info_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_address_use_case.dart';
import 'package:school_app_flutter/features/student/domain/usecases/update_student_personal_info_use_case.dart';

part 'student_event.dart';
part 'student_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final UpdateStudentPersonalInfoUseCase _updatePersonalInfoUseCase;
  final UpdateStudentAddressUseCase _updateAddressUseCase;
  final UpdateStudentAcademicInfoUseCase? _updateAcademicInfoUseCase;

  StudentBloc({
    required UpdateStudentPersonalInfoUseCase updatePersonalInfoUseCase,
    required UpdateStudentAddressUseCase updateAddressUseCase,
    UpdateStudentAcademicInfoUseCase? updateAcademicInfoUseCase,
  })  : _updatePersonalInfoUseCase = updatePersonalInfoUseCase,
        _updateAddressUseCase = updateAddressUseCase,
        _updateAcademicInfoUseCase = updateAcademicInfoUseCase,
        super(const StudentState.initial()) {
    on<StudentPersonalInfoUpdateRequested>(_onPersonalInfoUpdateRequested);
    on<StudentAddressUpdateRequested>(_onAddressUpdateRequested);
    on<StudentAcademicInfoUpdateRequested>(_onAcademicInfoUpdateRequested);
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
    emit(state.copyWith(
      status: StudentUpdateStatus.loading,
      operation: StudentUpdateOperation.personalInfo,
      errorMessage: null,
    ));
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
      (failure) => emit(state.copyWith(
        status: StudentUpdateStatus.failure,
        operation: StudentUpdateOperation.personalInfo,
        errorMessage: failure.message,
      )),
      (updatedStudent) => emit(state.copyWith(
        status: StudentUpdateStatus.success,
        operation: StudentUpdateOperation.personalInfo,
        updatedStudent: updatedStudent,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onAddressUpdateRequested(
    StudentAddressUpdateRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(state.copyWith(
      status: StudentUpdateStatus.loading,
      operation: StudentUpdateOperation.address,
      errorMessage: null,
    ));
    final result = await _updateAddressUseCase(
      studentId: event.studentId,
      city: event.city,
      district: event.district,
      municipality: event.municipality,
      neighborhood: event.neighborhood,
      address: event.address,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: StudentUpdateStatus.failure,
        operation: StudentUpdateOperation.address,
        errorMessage: failure.message,
      )),
      (updatedStudent) => emit(state.copyWith(
        status: StudentUpdateStatus.success,
        operation: StudentUpdateOperation.address,
        updatedStudent: updatedStudent,
        errorMessage: null,
      )),
    );
  }

  Future<void> _onAcademicInfoUpdateRequested(
    StudentAcademicInfoUpdateRequested event,
    Emitter<StudentState> emit,
  ) async {
    emit(state.copyWith(
      status: StudentUpdateStatus.loading,
      operation: StudentUpdateOperation.academicInfo,
      errorMessage: null,
    ));
    final updateUseCase = _updateAcademicInfoUseCase;
    if (updateUseCase == null) {
      emit(state.copyWith(
        status: StudentUpdateStatus.failure,
        operation: StudentUpdateOperation.academicInfo,
        errorMessage: 'Academic info update use case is not configured',
      ));
      return;
    }
    final result = await updateUseCase(
      studentId: event.studentId,
      schoolLevelId: event.schoolLevelId,
      schoolLevelGroupId: event.schoolLevelGroupId,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: StudentUpdateStatus.failure,
        operation: StudentUpdateOperation.academicInfo,
        errorMessage: failure.message,
      )),
      (updatedAcademicInfo) => emit(state.copyWith(
        status: StudentUpdateStatus.success,
        operation: StudentUpdateOperation.academicInfo,
        updatedAcademicInfo: updatedAcademicInfo,
        errorMessage: null,
      )),
    );
  }
}