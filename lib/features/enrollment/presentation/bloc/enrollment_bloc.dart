import 'dart:async';

import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary_page.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_preview_by_student_id_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/get_enrollment_summary_list_by_status_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_name_use_case.dart';
import 'package:school_app_flutter/features/enrollment/domain/usecases/search_enrollment_summary_by_status_and_academic_year_and_student_names_and_date_of_birth_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_summary_query.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';

// Ré-exporte les contrats de liste partagés (statut de chargement, type/photo de
// requête) pour que les consommateurs historiques de `enrollment_bloc.dart`
// (classes, finance, widgets de résultats) continuent d'y accéder sans import.
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_summary_query.dart';

part 'enrollment_event.dart';
part 'enrollment_state.dart';

class EnrollmentBloc extends Bloc<EnrollmentEvent, EnrollmentState> {
  static const int _defaultSummariesPageSize =
      AppConstants.enrollmentDefaultPageSize;

  final GetEnrollmentSummaryListByStatusUseCase
  _getEnrollmentSummaryListByStatusUseCase;
  final GetEnrollmentDetailUseCase _getEnrollmentDetailUseCase;
  final GetEnrollmentPreviewByStudentIdUseCase
  _getEnrollmentPreviewByStudentIdUseCase;
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
    required GetEnrollmentPreviewByStudentIdUseCase
    getEnrollmentPreviewByStudentIdUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNameUseCase
    searchByStudentNameUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndStudentNamesAndDateOfBirthUseCase
    searchByStudentNamesAndDateOfBirthUseCase,
    required SearchEnrollmentSummaryByStatusAndAcademicYearAndDateOfBirthUseCase
    searchByDateOfBirthUseCase,
  }) : _getEnrollmentSummaryListByStatusUseCase = getEnrollmentSummariesUseCase,
       _getEnrollmentDetailUseCase = getEnrollmentDetailUseCase,
       _getEnrollmentPreviewByStudentIdUseCase =
           getEnrollmentPreviewByStudentIdUseCase,
       _searchByStudentNameUseCase = searchByStudentNameUseCase,
       _searchByStudentNamesAndDateOfBirthUseCase =
           searchByStudentNamesAndDateOfBirthUseCase,
       _searchByDateOfBirthUseCase = searchByDateOfBirthUseCase,
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
    on<EnrollmentSummariesPageRequested>(_onSummariesPageRequested);
    on<EnrollmentDetailRequested>(_onDetailRequested);
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
        page: event.page,
        size: event.size,
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
        page: event.page,
        size: event.size,
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
        page: event.page,
        size: event.size,
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
        page: event.page,
        size: event.size,
        dateOfBirth: event.dateOfBirth,
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

  Future<void> _onSummariesPageRequested(
    EnrollmentSummariesPageRequested event,
    Emitter<EnrollmentState> emit,
  ) async {
    final lastSummariesQuery = state.lastSummariesQuery;
    if (lastSummariesQuery == null) {
      return;
    }

    final totalPages = state.summariesTotalPages;
    final maxPage = totalPages > 0 ? totalPages - 1 : event.page;
    final nextPage = event.page.clamp(0, maxPage);

    await _loadSummariesForQuery(
      emit,
      EnrollmentSummariesQuery(
        type: lastSummariesQuery.type,
        status: lastSummariesQuery.status,
        academicYearId: lastSummariesQuery.academicYearId,
        page: nextPage,
        size: lastSummariesQuery.size,
        firstName: lastSummariesQuery.firstName,
        lastName: lastSummariesQuery.lastName,
        surname: lastSummariesQuery.surname,
        dateOfBirth: lastSummariesQuery.dateOfBirth,
        schoolLevelGroupId: lastSummariesQuery.schoolLevelGroupId,
        schoolLevelId: lastSummariesQuery.schoolLevelId,
      ),
    );
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
        summariesErrorType: null,
        errorMessage: null,
      ),
    );

    final result = await switch (query.type) {
      EnrollmentSummaryQueryType.byStatus =>
        _getEnrollmentSummaryListByStatusUseCase(
          status: query.status,
          academicYearId: query.academicYearId,
          page: query.page,
          size: query.size,
        ),
      EnrollmentSummaryQueryType.byStudentName => _searchByStudentNameUseCase(
        status: query.status,
        academicYearId: query.academicYearId,
        firstName: query.firstName ?? '',
        lastName: query.lastName ?? '',
        surname: query.surname ?? '',
        page: query.page,
        size: query.size,
      ),
      EnrollmentSummaryQueryType.byStudentNamesAndDateOfBirth =>
        _searchByStudentNamesAndDateOfBirthUseCase(
          status: query.status,
          academicYearId: query.academicYearId,
          firstName: query.firstName ?? '',
          lastName: query.lastName ?? '',
          surname: query.surname ?? '',
          dateOfBirth: query.dateOfBirth ?? '',
          page: query.page,
          size: query.size,
        ),
      EnrollmentSummaryQueryType.byDateOfBirth => _searchByDateOfBirthUseCase(
        status: query.status,
        academicYearId: query.academicYearId,
        dateOfBirth: query.dateOfBirth ?? '',
        page: query.page,
        size: query.size,
      ),
      // `byAcademicInfo` appartient au listing LOCAL seul : le CONTRAT de
      // requête est partagé (`EnrollmentSummariesQuery`), les sources ne le
      // sont pas. Aucun événement de ce bloc ne produit ce type, et l'endpoint
      // online correspondant a été retiré — il exigeait le niveau en paramètre,
      // donc il ne pouvait de toute façon pas servir une recherche par
      // identité. Cette branche n'existe que pour l'exhaustivité de l'énumération.
      EnrollmentSummaryQueryType.byAcademicInfo => Future.value(
        const Left<Failure, EnrollmentSummaryPage>(
          ServerFailure('Query type not served by the online listing'),
        ),
      ),
    };

    result.fold(
      (failure) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.failure,
          summariesErrorType: _mapFailureToErrorType(failure),
          errorMessage: failure.message,
        ),
      ),
      (summaryPage) => emit(
        state.copyWith(
          summariesStatus: EnrollmentLoadStatus.success,
          summaries: summaryPage.content,
          // Utilise la page demandée (query.page) plutôt que celle renvoyée
          // par le backend, qui peut être incohérente selon les implémentations.
          summariesPage: query.page,
          summariesSize: summaryPage.size > 0
              ? summaryPage.size
              : _defaultSummariesPageSize,
          summariesTotalElements: summaryPage.totalElements,
          summariesTotalPages: summaryPage.totalPages,
          summariesErrorType: null,
          errorMessage: null,
        ),
      ),
    );
  }

  EnrollmentErrorType _mapFailureToErrorType(Failure failure) {
    return switch (failure) {
      NetworkFailure() => EnrollmentErrorType.network,
      InvalidCredentialsFailure() => EnrollmentErrorType.unauthorized,
      UnauthorizedFailure() => EnrollmentErrorType.forbidden,
      ServerFailure() => EnrollmentErrorType.server,
      _ => EnrollmentErrorType.unknown,
    };
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
}
