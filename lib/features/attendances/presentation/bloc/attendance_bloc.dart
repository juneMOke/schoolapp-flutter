import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/update_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetAttendanceUseCase _getAttendanceUseCase;
  final UpdateAttendanceUseCase _updateAttendanceUseCase;

  AttendanceBloc({
    required GetAttendanceUseCase getAttendanceUseCase,
    required UpdateAttendanceUseCase updateAttendanceUseCase,
  }) : _getAttendanceUseCase = getAttendanceUseCase,
       _updateAttendanceUseCase = updateAttendanceUseCase,
       super(const AttendanceState()) {
    on<AttendanceFetchRequested>(_onFetchRequested);
    on<AttendancePresenceToggled>(_onPresenceToggled);
    on<AttendanceAbsenceReasonChanged>(_onAbsenceReasonChanged);
    on<AttendanceAbsenceNoteChanged>(_onAbsenceNoteChanged);
    on<AttendanceSaveRequested>(_onSaveRequested);
    on<AttendanceSaveStatusResetRequested>(_onSaveStatusResetRequested);
    on<AttendanceResetRequested>(_onResetRequested);
  }

  Future<void> _onFetchRequested(
    AttendanceFetchRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(
      state.copyWith(
        fetchStatus: AttendanceStatus.loading,
        fetchErrorType: AttendanceErrorType.none,
      ),
    );

    final result = await _getAttendanceUseCase(
      classroomId: event.classroomId,
      date: event.date,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          fetchStatus: AttendanceStatus.failure,
          fetchErrorType: _mapFailureToErrorType(failure),
          saveStatus: AttendanceStatus.initial,
          saveErrorType: AttendanceErrorType.none,
        ),
      ),
      (records) {
        final draftRows = records
            .map(AttendanceEditableRow.fromRecord)
            .toList(growable: false);

        emit(
          state.copyWith(
            fetchStatus: AttendanceStatus.success,
            records: records,
            draftRows: draftRows,
            fetchErrorType: AttendanceErrorType.none,
            saveStatus: AttendanceStatus.initial,
            saveErrorType: AttendanceErrorType.none,
            activeClassroomId: event.classroomId,
            activeAcademicYearId: event.academicYearId,
            activeDate: event.date,
            hasUnsavedChanges: false,
            hasValidationErrors: _hasValidationErrors(draftRows),
            modifiedStudentIds: const <String>{},
          ),
        );
      },
    );
  }

  void _onPresenceToggled(
    AttendancePresenceToggled event,
    Emitter<AttendanceState> emit,
  ) {
    _updateDraftRows(
      emit,
      event.studentId,
      (row) => event.present
          ? row.copyWith(
              present: true,
              absenceReason: null,
              absenceReasonNote: '',
            )
          : row.copyWith(present: false),
    );
  }

  void _onAbsenceReasonChanged(
    AttendanceAbsenceReasonChanged event,
    Emitter<AttendanceState> emit,
  ) {
    _updateDraftRows(
      emit,
      event.studentId,
      (row) =>
          row.present ? row : row.copyWith(absenceReason: event.absenceReason),
    );
  }

  void _onAbsenceNoteChanged(
    AttendanceAbsenceNoteChanged event,
    Emitter<AttendanceState> emit,
  ) {
    _updateDraftRows(
      emit,
      event.studentId,
      (row) => row.present ? row : row.copyWith(absenceReasonNote: event.note),
    );
  }

  Future<void> _onSaveRequested(
    AttendanceSaveRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.fetchStatus != AttendanceStatus.success ||
        state.draftRows.isEmpty) {
      return;
    }

    if (state.hasValidationErrors ||
        state.activeClassroomId == null ||
        state.activeAcademicYearId == null ||
        state.activeDate == null) {
      emit(
        state.copyWith(
          saveStatus: AttendanceStatus.failure,
          saveErrorType: AttendanceErrorType.validation,
        ),
      );
      return;
    }

    if (!state.hasUnsavedChanges) {
      return;
    }

    emit(
      state.copyWith(
        saveStatus: AttendanceStatus.loading,
        saveErrorType: AttendanceErrorType.none,
      ),
    );

    final result = await _updateAttendanceUseCase(
      classroomId: state.activeClassroomId!,
      date: state.activeDate!,
      academicYearId: state.activeAcademicYearId!,
      updates: state.draftRows
          .map((row) => row.toUpdate())
          .toList(growable: false),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          saveStatus: AttendanceStatus.failure,
          saveErrorType: _mapFailureToErrorType(failure),
        ),
      ),
      (_) {
        final syncedRecords = _syncRecordsWithDraftRows(
          state.records,
          state.draftRows,
        );
        emit(
          state.copyWith(
            records: syncedRecords,
            saveStatus: AttendanceStatus.success,
            saveErrorType: AttendanceErrorType.none,
            hasUnsavedChanges: false,
            hasValidationErrors: false,
            modifiedStudentIds: const <String>{},
          ),
        );
      },
    );
  }

  void _onSaveStatusResetRequested(
    AttendanceSaveStatusResetRequested event,
    Emitter<AttendanceState> emit,
  ) {
    emit(
      state.copyWith(
        saveStatus: AttendanceStatus.initial,
        saveErrorType: AttendanceErrorType.none,
      ),
    );
  }

  void _onResetRequested(
    AttendanceResetRequested event,
    Emitter<AttendanceState> emit,
  ) {
    emit(const AttendanceState());
  }

  void _updateDraftRows(
    Emitter<AttendanceState> emit,
    String studentId,
    AttendanceEditableRow Function(AttendanceEditableRow row) transform,
  ) {
    final draftRows = state.draftRows
        .map((row) => row.studentId == studentId ? transform(row) : row)
        .toList(growable: false);
    final modifiedStudentIds = _computeModifiedStudentIds(
      state.records,
      draftRows,
    );

    emit(
      state.copyWith(
        draftRows: draftRows,
        hasUnsavedChanges: _hasUnsavedChanges(state.records, draftRows),
        hasValidationErrors: _hasValidationErrors(draftRows),
        modifiedStudentIds: modifiedStudentIds,
        saveStatus: AttendanceStatus.initial,
        saveErrorType: AttendanceErrorType.none,
      ),
    );
  }

  Set<String> _computeModifiedStudentIds(
    List<AttendanceRecord> records,
    List<AttendanceEditableRow> draftRows,
  ) {
    final recordByStudentId = {
      for (final record in records) record.studentId: record,
    };

    final modified = <String>{};

    for (final draft in draftRows) {
      final record = recordByStudentId[draft.studentId];
      if (record == null) {
        modified.add(draft.studentId);
        continue;
      }

      final isChanged =
          record.present != draft.present ||
          record.absenceReason != draft.absenceReason ||
          (record.absenceReasonNote ?? '').trim() !=
              draft.absenceReasonNote.trim();

      if (isChanged) {
        modified.add(draft.studentId);
      }
    }

    return modified;
  }

  bool _hasUnsavedChanges(
    List<AttendanceRecord> records,
    List<AttendanceEditableRow> draftRows,
  ) {
    if (records.length != draftRows.length) {
      return true;
    }

    for (var index = 0; index < records.length; index += 1) {
      final record = records[index];
      final draft = draftRows[index];

      if (record.studentId != draft.studentId ||
          record.present != draft.present ||
          record.absenceReason != draft.absenceReason ||
          (record.absenceReasonNote ?? '').trim() !=
              draft.absenceReasonNote.trim()) {
        return true;
      }
    }

    return false;
  }

  bool _hasValidationErrors(List<AttendanceEditableRow> draftRows) {
    return draftRows.any((row) => row.hasValidationError);
  }

  List<AttendanceRecord> _syncRecordsWithDraftRows(
    List<AttendanceRecord> records,
    List<AttendanceEditableRow> draftRows,
  ) {
    final draftByStudentId = {for (final row in draftRows) row.studentId: row};

    return records
        .map((record) {
          final draft = draftByStudentId[record.studentId];
          if (draft == null) {
            return record;
          }

          return AttendanceRecord(
            id: record.id,
            studentId: record.studentId,
            studentFirstName: record.studentFirstName,
            studentLastName: record.studentLastName,
            studentMiddleName: record.studentMiddleName,
            studentGender: record.studentGender,
            classroomId: record.classroomId,
            academicYearId: record.academicYearId,
            attendanceDate: record.attendanceDate,
            present: draft.present,
            absenceReason: draft.present ? null : draft.absenceReason,
            absenceReasonNote: draft.present
                ? null
                : draft.absenceReasonNote.trim().isEmpty
                ? null
                : draft.absenceReasonNote.trim(),
          );
        })
        .toList(growable: false);
  }

  AttendanceErrorType _mapFailureToErrorType(Failure failure) =>
      switch (failure) {
        NetworkFailure() => AttendanceErrorType.network,
        NotFoundFailure() => AttendanceErrorType.notFound,
        ValidationFailure() => AttendanceErrorType.validation,
        UnauthorizedFailure() => AttendanceErrorType.unauthorized,
        InvalidCredentialsFailure() => AttendanceErrorType.invalidCredentials,
        ServerFailure() => AttendanceErrorType.server,
        StorageFailure() => AttendanceErrorType.storage,
        AuthFailure() => AttendanceErrorType.auth,
        _ => AttendanceErrorType.unknown,
      };
}
