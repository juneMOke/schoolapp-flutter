import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/daily_attendance.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/load_daily_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/models/attendance_editable_row.dart';

class MockLoadDailyAttendanceUseCase extends Mock
    implements LoadDailyAttendanceUseCase {}

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

void main() {
  late MockLoadDailyAttendanceUseCase mockLoadDailyAttendance;

  setUp(() {
    mockLoadDailyAttendance = MockLoadDailyAttendanceUseCase();
  });

  AttendanceBloc buildBloc() =>
      AttendanceBloc(loadDailyAttendance: mockLoadDailyAttendance);

  group('AttendanceFetchRequested', () {
    blocTest<AttendanceBloc, AttendanceState>(
      'hydrates records and editable draft rows on success',
      setUp: () {
        when(
          () => mockLoadDailyAttendance(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
          ),
        ).thenAnswer(
          (_) async => Right(DailyAttendance(taken: true, records: [tRecord])),
        );
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
          callTaken: true,
          activeClassroomId: 'class-1',
          activeAcademicYearId: 'year-1',
          activeDate: tDate,
        ),
      ],
    );

    // Convention projet : HTTP 403 -> UnauthorizedFailure -> forbidden
    // (et non 401). Sans ce mapping, un 403 s'afficherait comme un 401.
    blocTest<AttendanceBloc, AttendanceState>(
      'mappe UnauthorizedFailure (HTTP 403) vers AttendanceErrorType.forbidden',
      setUp: () {
        when(
          () => mockLoadDailyAttendance(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
          ),
        ).thenAnswer(
          (_) async => const Left(UnauthorizedFailure('Access forbidden')),
        );
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
        const AttendanceState(
          fetchStatus: AttendanceStatus.failure,
          fetchErrorType: AttendanceErrorType.forbidden,
        ),
      ],
    );

    // HTTP 401 -> InvalidCredentialsFailure -> invalidCredentials (vue : 401).
    blocTest<AttendanceBloc, AttendanceState>(
      'mappe InvalidCredentialsFailure (HTTP 401) vers invalidCredentials',
      setUp: () {
        when(
          () => mockLoadDailyAttendance(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
          ),
        ).thenAnswer(
          (_) async =>
              const Left(InvalidCredentialsFailure('Invalid credentials')),
        );
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
        const AttendanceState(
          fetchStatus: AttendanceStatus.failure,
          fetchErrorType: AttendanceErrorType.invalidCredentials,
        ),
      ],
    );

    // Lecture offline-first : le repo local ne renvoie qu'un StorageFailure,
    // mappé sur AttendanceErrorType.storage (chemin d'erreur réel post-bascule).
    blocTest<AttendanceBloc, AttendanceState>(
      'mappe StorageFailure (lecture locale) vers AttendanceErrorType.storage',
      setUp: () {
        when(
          () => mockLoadDailyAttendance(
            classroomId: 'class-1',
            date: tDate,
            academicYearId: 'year-1',
          ),
        ).thenAnswer(
          (_) async => const Left(StorageFailure('local read failed')),
        );
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
        const AttendanceState(
          fetchStatus: AttendanceStatus.failure,
          fetchErrorType: AttendanceErrorType.storage,
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
}
