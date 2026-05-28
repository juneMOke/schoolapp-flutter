import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/update_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';

class MockGetAttendanceUseCase extends Mock implements GetAttendanceUseCase {}

class MockUpdateAttendanceUseCase extends Mock
    implements UpdateAttendanceUseCase {}

final tDate = DateTime(2026, 5, 1);

final tRecord = AttendanceRecord(
  id: 'attendance-1',
  studentId: 'student-1',
  studentFirstName: 'John',
  studentLastName: 'Doe',
  studentMiddleName: 'Junior',
  studentGender: StudentGender.male,
  classroomId: 'class-1',
  academicYearId: 'year-1',
  attendanceDate: tDate,
  present: true,
  absenceReason: null,
  absenceReasonNote: null,
);

final tDraft = AttendanceEditableRow.fromRecord(tRecord);

final tAbsentDraft = tDraft.copyWith(
  present: false,
  absenceReason: AbsenceReason.sickness,
  absenceReasonNote: 'Repos',
);

const tAbsentUpdate = AttendanceUpdate(
  studentId: 'student-1',
  studentFirstName: 'John',
  studentLastName: 'Doe',
  studentMiddleName: 'Junior',
  studentGender: StudentGender.male,
  present: false,
  absenceReason: AbsenceReason.sickness,
  absenceReasonNote: 'Repos',
);

void main() {
  late MockGetAttendanceUseCase mockGetAttendanceUseCase;
  late MockUpdateAttendanceUseCase mockUpdateAttendanceUseCase;

  setUp(() {
    mockGetAttendanceUseCase = MockGetAttendanceUseCase();
    mockUpdateAttendanceUseCase = MockUpdateAttendanceUseCase();
  });

  AttendanceBloc buildBloc() => AttendanceBloc(
    getAttendanceUseCase: mockGetAttendanceUseCase,
    updateAttendanceUseCase: mockUpdateAttendanceUseCase,
  );

  group('AttendanceFetchRequested', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'hydrates records and editable draft rows on success',
      setUp: () {
        when(
          () => mockGetAttendanceUseCase(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
          ),
        ).thenAnswer((_) async => Right([tRecord]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AttendanceFetchRequested(
          classroomId: 'class-1',
          date: tDate,
          academicYearId: 'year-1',
        ),
      ),
      expect: () => [
        const AttendanceState(fetchStatus: AttendanceStatus.loading),
        AttendanceState(
          fetchStatus: AttendanceStatus.success,
          records: [tRecord],
          draftRows: [tDraft],
          activeClassroomId: 'class-1',
          activeAcademicYearId: 'year-1',
          activeDate: tDate,
        ),
      ],
    );
  });

  group('AttendancePresenceToggled', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'marks rows as dirty and invalid when toggled absent without reason',
      build: buildBloc,
      seed: () => AttendanceState(
        fetchStatus: AttendanceStatus.success,
        records: [tRecord],
        draftRows: [tDraft],
        activeClassroomId: 'class-1',
        activeAcademicYearId: 'year-1',
        activeDate: tDate,
      ),
      act: (bloc) => bloc.add(
        const AttendancePresenceToggled(studentId: 'student-1', present: false),
      ),
      expect: () => [
        AttendanceState(
          fetchStatus: AttendanceStatus.success,
          records: [tRecord],
          draftRows: [tDraft.copyWith(present: false)],
          activeClassroomId: 'class-1',
          activeAcademicYearId: 'year-1',
          activeDate: tDate,
          hasUnsavedChanges: true,
          hasValidationErrors: true,
          modifiedStudentIds: const {'student-1'},
        ),
      ],
    );
  });

  group('AttendanceSaveRequested', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'saves all draft rows and clears dirty state on success',
      setUp: () {
        when(
          () => mockUpdateAttendanceUseCase(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
            updates: [tAbsentUpdate],
          ),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      seed: () => AttendanceState(
        fetchStatus: AttendanceStatus.success,
        records: [tRecord],
        draftRows: [tAbsentDraft],
        activeClassroomId: 'class-1',
        activeAcademicYearId: 'year-1',
        activeDate: tDate,
        hasUnsavedChanges: true,
      ),
      act: (bloc) => bloc.add(const AttendanceSaveRequested()),
      expect: () => [
        AttendanceState(
          fetchStatus: AttendanceStatus.success,
          records: [tRecord],
          draftRows: [tAbsentDraft],
          saveStatus: AttendanceStatus.loading,
          activeClassroomId: 'class-1',
          activeAcademicYearId: 'year-1',
          activeDate: tDate,
          hasUnsavedChanges: true,
        ),
        AttendanceState(
          fetchStatus: AttendanceStatus.success,
          records: [
            AttendanceRecord(
              id: 'attendance-1',
              studentId: 'student-1',
              studentFirstName: 'John',
              studentLastName: 'Doe',
              studentMiddleName: 'Junior',
              studentGender: StudentGender.male,
              classroomId: 'class-1',
              academicYearId: 'year-1',
              attendanceDate: tDate,
              present: false,
              absenceReason: AbsenceReason.sickness,
              absenceReasonNote: 'Repos',
            ),
          ],
          draftRows: [tAbsentDraft],
          saveStatus: AttendanceStatus.success,
          activeClassroomId: 'class-1',
          activeAcademicYearId: 'year-1',
          activeDate: tDate,
        ),
      ],
      verify: (_) {
        verify(
          () => mockUpdateAttendanceUseCase(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
            updates: [tAbsentUpdate],
          ),
        ).called(1);
      },
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'fails locally with validation error when an absent row has no reason',
      build: buildBloc,
      seed: () => AttendanceState(
        fetchStatus: AttendanceStatus.success,
        records: [tRecord],
        draftRows: [tDraft.copyWith(present: false)],
        activeClassroomId: 'class-1',
        activeAcademicYearId: 'year-1',
        activeDate: tDate,
        hasUnsavedChanges: true,
        hasValidationErrors: true,
      ),
      act: (bloc) => bloc.add(const AttendanceSaveRequested()),
      expect: () => [
        AttendanceState(
          fetchStatus: AttendanceStatus.success,
          records: [tRecord],
          draftRows: [tDraft.copyWith(present: false)],
          saveStatus: AttendanceStatus.failure,
          saveErrorType: AttendanceErrorType.validation,
          activeClassroomId: 'class-1',
          activeAcademicYearId: 'year-1',
          activeDate: tDate,
          hasUnsavedChanges: true,
          hasValidationErrors: true,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockUpdateAttendanceUseCase(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
            updates: [tAbsentUpdate],
          ),
        );
      },
    );
  });
}
