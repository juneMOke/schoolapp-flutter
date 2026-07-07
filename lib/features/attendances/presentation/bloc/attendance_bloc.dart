import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/load_daily_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_failure_mapper.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';

/// BLoC de la liste d'appel : **lecture** (offline-first) + **brouillon
/// éditable** (bascule présence, motif, note, « tout présent »).
///
/// **Lecture = offline-first (Phase 2)** : l'appel du jour est lu depuis le
/// cache LOCAL via [LoadDailyAttendanceUseCase] (roster `ref_classroom_members`
/// présent par défaut + exceptions locales), et non plus du réseau. Le roster
/// local est alimenté par le pull Classe au retour online ; hors ligne, l'appel
/// reste consultable.
///
/// **Écriture** : ce BLoC ne sauvegarde plus lui-même. La confirmation de
/// l'appel est dispatchée par l'UI (`attendance_save_overlay`) vers
/// `AttendanceOfflineBloc` (écriture locale + outbox). L'ancien chemin d'écriture
/// online (`AttendanceSaveRequested` → `UpdateAttendanceUseCase`) a été retiré.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final LoadDailyAttendanceUseCase _loadDailyAttendance;

  AttendanceBloc({required LoadDailyAttendanceUseCase loadDailyAttendance})
    : _loadDailyAttendance = loadDailyAttendance,
      super(const AttendanceState()) {
    on<AttendanceFetchRequested>(_onFetchRequested);
    on<AttendancePresenceToggled>(_onPresenceToggled);
    on<AttendanceAbsenceReasonChanged>(_onAbsenceReasonChanged);
    on<AttendanceAbsenceNoteChanged>(_onAbsenceNoteChanged);
    on<AttendanceSaveStatusResetRequested>(_onSaveStatusResetRequested);
    on<AttendanceResetRequested>(_onResetRequested);
    on<AttendanceMarkAllPresentRequested>(_onMarkAllPresentRequested);
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

    final result = await _loadDailyAttendance(
      classroomId: event.classroomId,
      date: event.date,
      academicYearId: event.academicYearId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          fetchStatus: AttendanceStatus.failure,
          fetchErrorType: mapFailureToAttendanceErrorType(failure),
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

  void _onMarkAllPresentRequested(
    AttendanceMarkAllPresentRequested event,
    Emitter<AttendanceState> emit,
  ) {
    if (state.fetchStatus != AttendanceStatus.success ||
        state.draftRows.isEmpty) {
      return;
    }

    final draftRows = state.draftRows
        .map(
          (row) => row.copyWith(
            present: true,
            absenceReason: null,
            absenceReasonNote: '',
          ),
        )
        .toList(growable: false);

    emit(
      state.copyWith(
        draftRows: draftRows,
        hasUnsavedChanges: _hasUnsavedChanges(state.records, draftRows),
        hasValidationErrors: false,
        modifiedStudentIds: _computeModifiedStudentIds(
          state.records,
          draftRows,
        ),
        saveStatus: AttendanceStatus.initial,
        saveErrorType: AttendanceErrorType.none,
      ),
    );
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
}
