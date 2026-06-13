import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/create_disciplinary_case_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_disciplinary_case_detail_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_disciplinary_case_list_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';

class DisciplinaryCaseBloc
    extends Bloc<DisciplinaryCaseEvent, DisciplinaryCaseState> {
  final GetDisciplinaryCaseListUseCase _getDisciplinaryCaseListUseCase;
  final GetDisciplinaryCaseDetailUseCase _getDisciplinaryCaseDetailUseCase;
  final CreateDisciplinaryCaseUseCase _createDisciplinaryCaseUseCase;

  DisciplinaryCaseBloc({
    required GetDisciplinaryCaseListUseCase getDisciplinaryCaseListUseCase,
    required GetDisciplinaryCaseDetailUseCase getDisciplinaryCaseDetailUseCase,
    required CreateDisciplinaryCaseUseCase createDisciplinaryCaseUseCase,
  }) : _getDisciplinaryCaseListUseCase = getDisciplinaryCaseListUseCase,
       _getDisciplinaryCaseDetailUseCase = getDisciplinaryCaseDetailUseCase,
       _createDisciplinaryCaseUseCase = createDisciplinaryCaseUseCase,
       super(const DisciplinaryCaseState()) {
    on<DisciplinaryCaseListRequested>(_onListRequested);
    on<DisciplinaryCaseDetailRequested>(_onDetailRequested);
    on<DisciplinaryCaseCreateRequested>(_onCreateRequested);
    on<DisciplinaryCaseCreateStatusResetRequested>(
      _onCreateStatusResetRequested,
    );
    on<DisciplinaryCaseResetRequested>(_onResetRequested);
  }

  Future<void> _onListRequested(
    DisciplinaryCaseListRequested event,
    Emitter<DisciplinaryCaseState> emit,
  ) async {
    emit(
      state.copyWith(
        listStatus: DisciplinaryCaseStatusState.loading,
        listErrorType: DisciplinaryCaseErrorType.none,
      ),
    );

    final result = await _getDisciplinaryCaseListUseCase(
      studentId: event.studentId,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          listStatus: DisciplinaryCaseStatusState.failure,
          listErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (cases) => emit(
        state.copyWith(
          listStatus: DisciplinaryCaseStatusState.success,
          cases: cases,
          listErrorType: DisciplinaryCaseErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onDetailRequested(
    DisciplinaryCaseDetailRequested event,
    Emitter<DisciplinaryCaseState> emit,
  ) async {
    emit(
      state.copyWith(
        detailStatus: DisciplinaryCaseStatusState.loading,
        detailErrorType: DisciplinaryCaseErrorType.none,
      ),
    );

    final result = await _getDisciplinaryCaseDetailUseCase(
      caseId: event.caseId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          detailStatus: DisciplinaryCaseStatusState.failure,
          detailErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (caseDetail) => emit(
        state.copyWith(
          detailStatus: DisciplinaryCaseStatusState.success,
          selectedCase: caseDetail,
          detailErrorType: DisciplinaryCaseErrorType.none,
        ),
      ),
    );
  }

  Future<void> _onCreateRequested(
    DisciplinaryCaseCreateRequested event,
    Emitter<DisciplinaryCaseState> emit,
  ) async {
    emit(
      state.copyWith(
        createStatus: DisciplinaryCaseStatusState.loading,
        createErrorType: DisciplinaryCaseErrorType.none,
      ),
    );

    final result = await _createDisciplinaryCaseUseCase(
      studentId: event.studentId,
      studentFirstName: event.studentFirstName,
      studentLastName: event.studentLastName,
      studentMiddleName: event.studentMiddleName,
      studentGender: event.studentGender,
      disciplinaryCaseDate: event.disciplinaryCaseDate,
      academicYearId: event.academicYearId,
      title: event.title,
      content: event.content,
      category: event.category,
      severity: event.severity,
      sanction: event.sanction,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          createStatus: DisciplinaryCaseStatusState.failure,
          createErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (createdCase) => emit(
        state.copyWith(
          createStatus: DisciplinaryCaseStatusState.success,
          createdCase: createdCase,
          createErrorType: DisciplinaryCaseErrorType.none,
          cases: [createdCase, ...state.cases],
        ),
      ),
    );
  }

  void _onCreateStatusResetRequested(
    DisciplinaryCaseCreateStatusResetRequested event,
    Emitter<DisciplinaryCaseState> emit,
  ) {
    emit(
      state.copyWith(
        createStatus: DisciplinaryCaseStatusState.initial,
        createdCase: null,
        createErrorType: DisciplinaryCaseErrorType.none,
      ),
    );
  }

  void _onResetRequested(
    DisciplinaryCaseResetRequested event,
    Emitter<DisciplinaryCaseState> emit,
  ) {
    emit(const DisciplinaryCaseState());
  }

  DisciplinaryCaseErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => DisciplinaryCaseErrorType.network,
        NotFoundFailure() => DisciplinaryCaseErrorType.notFound,
        ValidationFailure() => DisciplinaryCaseErrorType.validation,
        // Convention projet : HTTP 403 -> UnauthorizedFailure -> forbidden,
        // HTTP 401 -> InvalidCredentialsFailure -> 401.
        UnauthorizedFailure() => DisciplinaryCaseErrorType.forbidden,
        InvalidCredentialsFailure() =>
          DisciplinaryCaseErrorType.invalidCredentials,
        ServerFailure() => DisciplinaryCaseErrorType.server,
        StorageFailure() => DisciplinaryCaseErrorType.storage,
        AuthFailure() => DisciplinaryCaseErrorType.auth,
        _ => DisciplinaryCaseErrorType.unknown,
      };
}
