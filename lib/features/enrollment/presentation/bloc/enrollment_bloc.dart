import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/create_enrollment_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_preview_by_student_id_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_academic_info_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/update_enrollment_status_use_case.dart';

part 'enrollment_event.dart';
part 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  final GetEnrollmentSummaryListByStatusUseCase
  _getEnrollmentSummaryListByStatusUseCase;
  final GetEnrollmentDetailUseCase _getEnrollmentDetailUseCase;
  final GetEnrollmentPreviewByStudentIdUseCase
  _getEnrollmentPreviewByStudentIdUseCase;
  final CreateEnrollmentUseCase _createEnrollmentUseCase;
  final SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
  _searchByStudentNameUseCase;
  final SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase
  _searchByStudentNamesAndDateOfBirthUseCase;
  final SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase
  _searchByDateOfBirthUseCase;
  final SearchEnrollmentSummaryByAcademicInfoUseCase
  _searchByAcademicInfoUseCase;
  final UpdateEnrollmentStatusUseCase _updateEnrollmentStatusUseCase;

  EnrollmentBloc({
    required GetEnrollmentSummaryListByStatusUseCase
    getEnrollmentSummariesUseCase,
    required GetEnrollmentDetailUseCase getEnrollmentDetailUseCase,
    required GetEnrollmentPreviewByStudentIdUseCase
    getEnrollmentPreviewByStudentIdUseCase,
    required CreateEnrollmentUseCase createEnrollmentUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
    searchByStudentNameUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase
    searchByStudentNamesAndDateOfBirthUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase
    searchByDateOfBirthUseCase,
    required SearchEnrollmentSummaryByAcademicInfoUseCase
    searchByAcademicInfoUseCase,
    required UpdateEnrollmentStatusUseCase updateEnrollmentStatusUseCase,
  }) : _getEnrollmentSummaryListByStatusUseCase = getEnrollmentSummariesUseCase,
       _getEnrollmentDetailUseCase = getEnrollmentDetailUseCase,
       _getEnrollmentPreviewByStudentIdUseCase =
           getEnrollmentPreviewByStudentIdUseCase,
       _createEnrollmentUseCase = createEnrollmentUseCase,
       _searchByStudentNameUseCase = searchByStudentNameUseCase,
       _searchByStudentNamesAndDateOfBirthUseCase =
           searchByStudentNamesAndDateOfBirthUseCase,
       _searchByDateOfBirthUseCase = searchByDateOfBirthUseCase,
       _searchByAcademicInfoUseCase = searchByAcademicInfoUseCase,
       _updateEnrollmentStatusUseCase = updateEnrollmentStatusUseCase,
       super(const EnrollmentState.initial()) {
    on<EnrollmentResetRequested>(_onResetRequested);
    on<EnrollmentSummariesRefreshRequested>(_onSummariesRefreshRequested);
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
    on<EnrollmentSummariesByAcademicInfoRequested>(
      _onSummariesByAcademicInfoRequested,
    );
    on<EnrollmentDetailRequested>(_onDetailRequested);
    on<EnrollmentNewDetailInitialized>(_onNewDetailInitialized);
    on<EnrollmentCreateRequested>(_onCreateRequested);
    on<EnrollmentCreateResultConsumed>(_onCreateResultConsumed);
    on<EnrollmentStatusUpdateRequested>(_onStatusUpdateRequested);
    on<EnrollmentStatusUpdateResultConsumed>(_onStatusUpdateResultConsumed);
    on<EnrollmentPreviewByStudentIdRequested>(_onPreviewByStudentIdRequested);
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
    await _loadSummariesForQuery(
      emit,
      EnrollmentSummariesQuery(
        type: EnrollmentSummaryQueryType.byStatus,
        status: event.status,
        academicYearId: event.academicYearId,
      ),
    );
  }

  Future<void> _onSummariesByStudentNameRequested(
    EnrollmentSummariesByStudentNameRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    await _loadSummariesForQuery(
      emit,
      EnrollmentSummariesQuery(
        type: EnrollmentSummaryQueryType.byStudentName,
        status: event.status,
        academicYearId: event.academicYearId,
        firstName: event.firstName,
        lastName: event.lastName,
        surname: event.surname,
      ),
    );
  }

  Future<void> _onSummariesByStudentNamesAndDateOfBirthRequested(
    EnrollmentSummariesByStudentNamesAndDateOfBirthRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    await _loadSummariesForQuery(
      emit,
      EnrollmentSummariesQuery(
        type: EnrollmentSummaryQueryType.byStudentNamesAndDateOfBirth,
        status: event.status,
        academicYearId: event.academicYearId,
        firstName: event.firstName,
        lastName: event.lastName,
        surname: event.surname,
        dateOfBirth: event.dateOfBirth,
      ),
    );
  }

  Future<void> _onSummariesByDateOfBirthRequested(
    EnrollmentSummariesByDateOfBirthRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    await _loadSummariesForQuery(
      emit,
      EnrollmentSummariesQuery(
        type: EnrollmentSummaryQueryType.byDateOfBirth,
        status: event.status,
        academicYearId: event.academicYearId,
        dateOfBirth: event.dateOfBirth,
      ),
    );
  }

  Future<void> _onSummariesByAcademicInfoRequested(
    EnrollmentSummariesByAcademicInfoRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    await _loadSummariesForQuery(
      emit,
      EnrollmentSummariesQuery(
        type: EnrollmentSummaryQueryType.byAcademicInfo,
        status: '',
        academicYearId: '',
        firstName: event.firstName,
        lastName: event.lastName,
        surname: event.surname,
        schoolLevelGroupId: event.schoolLevelGroupId,
        schoolLevelId: event.schoolLevelId,
      ),
    );
  }

  Future<void> _onSummariesRefreshRequested(
    EnrollmentSummariesRefreshRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    final lastSummariesQuery = state.lastSummariesQuery;
    if (lastSummariesQuery == null) {
      return;
    }

    await _loadSummariesForQuery(emit, lastSummariesQuery);
  }

  Future<void> _loadSummariesForQuery(
    Emitter<EnrollmentState> emit,
    EnrollmentSummariesQuery query,
  ) async {
    emit(
      state.copyWith(
        summariesStatus: EnrollmentLoadStatus.loading,
        summariesQueryType: query.type,
        lastSummariesQuery: query,
        errorMessage: null,
      ),
    );

    final result = await switch (query.type) {
      EnrollmentSummaryQueryType.byStatus =>
        _getEnrollmentSummaryListByStatusUseCase(
          status: query.status,
          academicYearId: query.academicYearId,
        ),
      EnrollmentSummaryQueryType.byStudentName => _searchByStudentNameUseCase(
        status: query.status,
        academicYearId: query.academicYearId,
        firstName: query.firstName ?? '',
        lastName: query.lastName ?? '',
        surname: query.surname ?? '',
      ),
      EnrollmentSummaryQueryType.byStudentNamesAndDateOfBirth =>
        _searchByStudentNamesAndDateOfBirthUseCase(
          status: query.status,
          academicYearId: query.academicYearId,
          firstName: query.firstName ?? '',
          lastName: query.lastName ?? '',
          surname: query.surname ?? '',
          dateOfBirth: query.dateOfBirth ?? '',
        ),
      EnrollmentSummaryQueryType.byDateOfBirth => _searchByDateOfBirthUseCase(
        status: query.status,
        academicYearId: query.academicYearId,
        dateOfBirth: query.dateOfBirth ?? '',
      ),
      EnrollmentSummaryQueryType.byAcademicInfo => _searchByAcademicInfoUseCase(
        firstName: query.firstName ?? '',
        lastName: query.lastName ?? '',
        surname: query.surname ?? '',
        schoolLevelGroupId: query.schoolLevelGroupId ?? '',
        schoolLevelId: query.schoolLevelId ?? '',
      ),
    };

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
    // En mode silencieux (refresh après sauvegarde), on ne repasse pas par
    // l'état loading pour ne pas détruire le stepper et perdre l'étape courante.
    if (!event.silent) {
      emit(
        state.copyWith(
          detailStatus: EnrollmentLoadStatus.loading,
          errorMessage: null,
        ),
      );
    }

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

  Future<void> _onNewDetailInitialized(
    EnrollmentNewDetailInitialized event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        detailStatus: EnrollmentLoadStatus.success,
        detail: EnrollmentDetail.empty(),
        errorMessage: null,
      ),
    );
  }

  Future<void> _onPreviewByStudentIdRequested(
    EnrollmentPreviewByStudentIdRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    if (!event.silent) {
      emit(
        state.copyWith(
          previewStatus: EnrollmentLoadStatus.loading,
          errorMessage: null,
        ),
      );
    }

    final result = await _getEnrollmentPreviewByStudentIdUseCase(
      studentId: event.studentId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          previewStatus: EnrollmentLoadStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (preview) => emit(
        state.copyWith(
          previewStatus: EnrollmentLoadStatus.success,
          preview: preview,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onCreateRequested(
    EnrollmentCreateRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        createStatus: EnrollmentLoadStatus.loading,
        createdEnrollmentSummary: null,
        errorMessage: null,
      ),
    );

    final result = await _createEnrollmentUseCase(
      firstName: event.firstName,
      lastName: event.lastName,
      surname: event.surname,
      dateOfBirth: event.dateOfBirth,
      birthPlace: event.birthPlace,
      nationality: event.nationality,
      gender: event.gender,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          createStatus: EnrollmentLoadStatus.failure,
          createdEnrollmentSummary: null,
          errorMessage: failure.message,
        ),
      ),
      (createdEnrollmentSummary) => emit(
        state.copyWith(
          createStatus: EnrollmentLoadStatus.success,
          createdEnrollmentSummary: createdEnrollmentSummary,
          errorMessage: null,
        ),
      ),
    );
  }

  Future<void> _onStatusUpdateRequested(
    EnrollmentStatusUpdateRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    emit(
      state.copyWith(
        statusUpdateStatus: EnrollmentLoadStatus.loading,
        updatedEnrollmentSummary: null,
        errorMessage: null,
      ),
    );

    final result = await _updateEnrollmentStatusUseCase(
      enrollmentId: event.enrollmentId,
      status: event.status,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          statusUpdateStatus: EnrollmentLoadStatus.failure,
          updatedEnrollmentSummary: null,
          errorMessage: failure.message,
        ),
      ),
      (updatedEnrollmentSummary) {
        final updatedSummaries = state.summaries
            .map(
              (summary) => summary.enrollmentId == updatedEnrollmentSummary.enrollmentId
                  ? updatedEnrollmentSummary
                  : summary,
            )
            .toList(growable: false);

        emit(
          state.copyWith(
            statusUpdateStatus: EnrollmentLoadStatus.success,
            updatedEnrollmentSummary: updatedEnrollmentSummary,
            summaries: updatedSummaries,
            errorMessage: null,
          ),
        );
      },
    );
  }

  FutureOr<void> _onCreateResultConsumed(
    EnrollmentCreateResultConsumed event,
    Emitter<EnrollmentState> emit,
  ) {
    emit(
      state.copyWith(
        createStatus: EnrollmentLoadStatus.initial,
        createdEnrollmentSummary: null,
      ),
    );
  }

  FutureOr<void> _onStatusUpdateResultConsumed(
    EnrollmentStatusUpdateResultConsumed event,
    Emitter<EnrollmentState> emit,
  ) {
    emit(
      state.copyWith(
        statusUpdateStatus: EnrollmentLoadStatus.initial,
        updatedEnrollmentSummary: null,
      ),
    );
  }
}
