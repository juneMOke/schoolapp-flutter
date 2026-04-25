import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/update_student_charge_expected_amount_usecase.dart';

part 'student_charges_event.dart';
part 'student_charges_state.dart';

class StudentChargesBloc
    extends Bloc<StudentChargesEvent, StudentChargesState> {
  final GetStudentChargesUseCase _getStudentChargesUseCase;
  final GetStudentChargesByAcademicYearUseCase?
      _getStudentChargesByAcademicYearUseCase;
  final UpdateStudentChargeExpectedAmountUseCase
      _updateStudentChargeExpectedAmountUseCase;

  StudentChargesBloc({
    required GetStudentChargesUseCase getStudentChargesUseCase,
    GetStudentChargesByAcademicYearUseCase?
        getStudentChargesByAcademicYearUseCase,
    required UpdateStudentChargeExpectedAmountUseCase
        updateStudentChargeExpectedAmountUseCase,
  }) : _getStudentChargesUseCase = getStudentChargesUseCase,
       _getStudentChargesByAcademicYearUseCase =
           getStudentChargesByAcademicYearUseCase,
       _updateStudentChargeExpectedAmountUseCase =
           updateStudentChargeExpectedAmountUseCase,
       super(const StudentChargesState()) {
    on<StudentChargesRequested>(_onStudentChargesRequested);
    on<StudentChargesByAcademicYearRequested>(
      _onStudentChargesByAcademicYearRequested,
    );
    on<StudentChargesDraftSaved>(_onStudentChargesDraftSaved);
    on<StudentChargeExpectedAmountUpdateRequested>(
      _onStudentChargeExpectedAmountUpdateRequested,
    );
  }

  Future<void> _onStudentChargesRequested(
    StudentChargesRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StudentChargesStatus.loading,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: null,
      ),
    );

    final result = await _getStudentChargesUseCase(
      GetStudentChargesParams(
        studentId: event.studentId,
        levelId: event.levelId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StudentChargesStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          updatingChargeId: null,
        ),
      ),
      (studentCharges) => emit(
        state.copyWith(
          status: StudentChargesStatus.success,
          studentCharges: studentCharges,
          errorType: StudentChargesErrorType.none,
          updatingChargeId: null,
        ),
      ),
    );
  }

  Future<void> _onStudentChargesByAcademicYearRequested(
    StudentChargesByAcademicYearRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StudentChargesStatus.loading,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: null,
      ),
    );

    if (_getStudentChargesByAcademicYearUseCase == null) {
      emit(
        state.copyWith(
          status: StudentChargesStatus.failure,
          errorType: StudentChargesErrorType.unknown,
          updatingChargeId: null,
        ),
      );
      return;
    }

    final result = await _getStudentChargesByAcademicYearUseCase(
      GetStudentChargesByAcademicYearParams(
        studentId: event.studentId,
        academicYearId: event.academicYearId,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StudentChargesStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          updatingChargeId: null,
        ),
      ),
      (studentCharges) => emit(
        state.copyWith(
          status: StudentChargesStatus.success,
          studentCharges: studentCharges,
          errorType: StudentChargesErrorType.none,
          updatingChargeId: null,
        ),
      ),
    );
  }

  StudentChargesErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => StudentChargesErrorType.network,
        NotFoundFailure() => StudentChargesErrorType.notFound,
        ValidationFailure() => StudentChargesErrorType.validation,
        UnauthorizedFailure() => StudentChargesErrorType.unauthorized,
        InvalidCredentialsFailure() =>
          StudentChargesErrorType.invalidCredentials,
        ServerFailure() => StudentChargesErrorType.server,
        StorageFailure() => StudentChargesErrorType.storage,
        AuthFailure() => StudentChargesErrorType.auth,
        _ => StudentChargesErrorType.unknown,
      };

  void _onStudentChargesDraftSaved(
    StudentChargesDraftSaved event,
    Emitter<StudentChargesState> emit,
  ) {
    emit(
      state.copyWith(
        status: StudentChargesStatus.success,
        studentCharges: event.studentCharges,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: null,
      ),
    );
  }

  Future<void> _onStudentChargeExpectedAmountUpdateRequested(
    StudentChargeExpectedAmountUpdateRequested event,
    Emitter<StudentChargesState> emit,
  ) async {
    emit(
      state.copyWith(
        status: StudentChargesStatus.loading,
        errorType: StudentChargesErrorType.none,
        updatingChargeId: event.studentChargeId,
      ),
    );

    final result = await _updateStudentChargeExpectedAmountUseCase(
      UpdateStudentChargeExpectedAmountParams(
        studentChargeId: event.studentChargeId,
        studentId: event.studentId,
        expectedAmountInCents: event.expectedAmountInCents,
      ),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: StudentChargesStatus.failure,
          errorType: _mapFailureToErrorType(failure),
          updatingChargeId: event.studentChargeId,
        ),
      ),
      (updatedCharge) {
        final updatedCharges = state.studentCharges
            .map(
              (charge) =>
                  charge.id == updatedCharge.id ? updatedCharge : charge,
            )
            .toList(growable: false);

        emit(
          state.copyWith(
            status: StudentChargesStatus.success,
            studentCharges: updatedCharges,
            errorType: StudentChargesErrorType.none,
            updatingChargeId: null,
          ),
        );
      },
    );
  }
}
