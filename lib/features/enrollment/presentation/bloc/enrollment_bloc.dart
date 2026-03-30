import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';

part 'enrollment_event.dart';
part 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final GetEnrollmentSummaryListByStatusUseCase
  _getEnrollmentSummaryListByStatusUseCase;
  final GetEnrollmentDetailUseCase _getEnrollmentDetailUseCase;
  final SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
  _searchByStudentNameUseCase;
  final SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase
  _searchByStudentNamesAndDateOfBirthUseCase;
  final SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase
  _searchByDateOfBirthUseCase;

  EnrollmentBloc({
    required GetEnrollmentSummaryListByStatusUseCase
    getEnrollmentSummariesUseCase,
    required GetEnrollmentDetailUseCase getEnrollmentDetailUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
    searchByStudentNameUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase
    searchByStudentNamesAndDateOfBirthUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase
    searchByDateOfBirthUseCase,
  }) : _getEnrollmentSummaryListByStatusUseCase = getEnrollmentSummariesUseCase,
       _getEnrollmentDetailUseCase = getEnrollmentDetailUseCase,
       _searchByStudentNameUseCase = searchByStudentNameUseCase,
       _searchByStudentNamesAndDateOfBirthUseCase =
           searchByStudentNamesAndDateOfBirthUseCase,
       _searchByDateOfBirthUseCase = searchByDateOfBirthUseCase,
       super(const EnrollmentState.initial()) {

    on<EnrollmentResetRequested>(_onResetRequested);
    on<EnrollmentSummariesRequested>(_onSummariesRequested);
    on<EnrollmentSummariesByStudentNameRequested>(
      _onSummariesByStudentNameRequested,
    );
    on<EnrollmentSummariesByStudentNamesAndDateOfBirthRequested>(
      _onSummariesByStudentNamesAndDateOfBirthRequested,
    );
    on<EnrollmentSummariesByDateOfBirthRequested>(
      _onSummariesByDateOfBirthRequested,
    );
    on<EnrollmentDetailRequested>(_onDetailRequested);

  }

  FutureOr<void> _onResetRequested(
    EnrollmentResetRequested event,
    Emitter<EnrollmentState> emit,
  ) {
    emit(const EnrollmentState.initial());
  }

  Future<void> _onSummariesRequested(
    EnrollmentSummariesRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        summariesStatus: EnrollmentLoadStatus.loading,
        summariesQueryType: EnrollmentSummaryQueryType.byStatus,
        errorMessage: null,
      ),
    );

    final result = await _getEnrollmentSummaryListByStatusUseCase(
      status: event.status,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (summaries) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.success,
          summaries: summaries,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onSummariesByStudentNameRequested(
    EnrollmentSummariesByStudentNameRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        summariesStatus: EnrollmentLoadStatus.loading,
        summariesQueryType: EnrollmentSummaryQueryType.byStudentName,
        errorMessage: null,
      ),
    );

    final result = await _searchByStudentNameUseCase(
      status: event.status,
      academicYearId: event.academicYearId,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (summaries) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.success,
          summaries: summaries,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onSummariesByStudentNamesAndDateOfBirthRequested(
    EnrollmentSummariesByStudentNamesAndDateOfBirthRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        summariesStatus: EnrollmentLoadStatus.loading,
        summariesQueryType:
            EnrollmentSummaryQueryType.byStudentNamesAndDateOfBirth,
        errorMessage: null,
      ),
    );

    final result = await _searchByStudentNamesAndDateOfBirthUseCase(
      status: event.status,
      academicYearId: event.academicYearId,
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      dateOfBirth: event.dateOfBirth,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (summaries) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.success,
          summaries: summaries,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onSummariesByDateOfBirthRequested(
    EnrollmentSummariesByDateOfBirthRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        summariesStatus: EnrollmentLoadStatus.loading,
        summariesQueryType: EnrollmentSummaryQueryType.byDateOfBirth,
        errorMessage: null,
      ),
    );

    final result = await _searchByDateOfBirthUseCase(
      status: event.status,
      academicYearId: event.academicYearId,
      dateOfBirth: event.dateOfBirth,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (summaries) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.success,
          summaries: summaries,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onDetailRequested(
    EnrollmentDetailRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        detailStatus: EnrollmentLoadStatus.loading,
        errorMessage: null,
      ),
    );

    final result = await _getEnrollmentDetailUseCase(
      enrollmentId: event.enrollmentId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: EnrollmentLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (detail) => emit(
        state.copyWith(
          detailStatus: EnrollmentLoadStatus.success,
          detail: detail,
          errorMessage: null,
        ),
      ),
    );
  }
}
