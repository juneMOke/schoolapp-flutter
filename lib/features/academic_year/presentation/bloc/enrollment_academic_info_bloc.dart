import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academic_year/domain/usecases/update_enrollment_academic_info_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_academic_info_response.dart';

part 'enrollment_academic_info_event.dart';
part 'enrollment_academic_info_state.dart';

class EnrollmentAcademicInfoBloc
    extends Bloc<EnrollmentAcademicInfoEvent, EnrollmentAcademicInfoState> {
  final UpdateEnrollmentAcademicInfoUseCase _updateUseCase;

  EnrollmentAcademicInfoBloc({
    required UpdateEnrollmentAcademicInfoUseCase updateUseCase,
  })  : _updateUseCase = updateUseCase,
        super(const EnrollmentAcademicInfoState.initial()) {
    on<EnrollmentAcademicInfoUpdateRequested>(_onUpdateRequested);
    on<EnrollmentAcademicInfoStateReset>(_onStateReset);
  }

  FutureOr<void> _onStateReset(
    EnrollmentAcademicInfoStateReset event,
    Emitter<EnrollmentAcademicInfoState> emit,
  ) {
    emit(const EnrollmentAcademicInfoState.initial());
  }

  Future<void> _onUpdateRequested(
    EnrollmentAcademicInfoUpdateRequested event,
    Emitter<EnrollmentAcademicInfoState> emit,
  ) async {
    emit(state.copyWith(
      status: EnrollmentAcademicInfoStatus.loading,
      errorMessage: null,
    ));

    final result = await _updateUseCase(
      studentId: event.enrollmentId,
      academicYearId: event.academicYearId,
      previousSchoolName: event.previousSchoolName,
      previousAcademicYear: event.previousAcademicYear,
      previousSchoolLevelGroup: event.previousSchoolLevelGroup,
      previousSchoolLevel: event.previousSchoolLevel,
      previousRate: event.previousRate,
      previousRank: event.previousRank,
      validatedPreviousYear: event.validatedPreviousYear,
      transferReason: event.transferReason,
      cancellationReason: event.cancellationReason,
      schoolLevelId: event.schoolLevelId,
      schoolLevelGroupId: event.schoolLevelGroupId,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: EnrollmentAcademicInfoStatus.failure,
        errorMessage: failure.message,
      )),
      (updatedDetail) => emit(state.copyWith(
        status: EnrollmentAcademicInfoStatus.success,
        updatedDetail: updatedDetail,
        errorMessage: null,
      )),
    );
  }
}
