import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_student_attendance_summary_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/student_attendance_summary_state.dart';

class MockGetStudentAttendanceSummaryUseCase extends Mock
    implements GetStudentAttendanceSummaryUseCase {}

void main() {
  late MockGetStudentAttendanceSummaryUseCase mockUseCase;

  final tSummary = StudentAttendanceSummary(
    studentId: '98f5',
    firstName: 'John',
    lastName: 'Doe',
    academicYearName: '2025-2026',
    period: StatsPeriod.month,
    windowStart: DateTime(2026, 2, 1),
    windowEnd: DateTime(2026, 2, 28),
    presenceRate: 86.4,
    presentDays: 19,
    justifiedAbsenceDays: 2,
    unjustifiedAbsenceDays: 1,
    absences: const [],
  );

  setUpAll(() => registerFallbackValue(StatsPeriod.year));

  setUp(() => mockUseCase = MockGetStudentAttendanceSummaryUseCase());

  StudentAttendanceSummaryBloc buildBloc() => StudentAttendanceSummaryBloc(
    getStudentAttendanceSummaryUseCase: mockUseCase,
  );

  void stubUseCase(Either<Failure, StudentAttendanceSummary> answer) {
    when(
      () => mockUseCase(
        studentId: any(named: 'studentId'),
        period: any(named: 'period'),
        month: any(named: 'month'),
        week: any(named: 'week'),
      ),
    ).thenAnswer((_) async => answer);
  }

  blocTest<StudentAttendanceSummaryBloc, StudentAttendanceSummaryState>(
    'emet [loading, success] sur succes',
    setUp: () => stubUseCase(Right(tSummary)),
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const StudentAttendanceSummaryRequested(studentId: '98f5')),
    expect: () => [
      const StudentAttendanceSummaryState(
        status: StudentAttendanceSummaryStatus.loading,
      ),
      StudentAttendanceSummaryState(
        status: StudentAttendanceSummaryStatus.success,
        summary: tSummary,
      ),
    ],
  );

  blocTest<StudentAttendanceSummaryBloc, StudentAttendanceSummaryState>(
    'emet [loading, failure(forbidden)] sur UnauthorizedFailure (403)',
    setUp: () => stubUseCase(const Left(UnauthorizedFailure())),
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const StudentAttendanceSummaryRequested(studentId: '98f5')),
    expect: () => [
      const StudentAttendanceSummaryState(
        status: StudentAttendanceSummaryStatus.loading,
      ),
      const StudentAttendanceSummaryState(
        status: StudentAttendanceSummaryStatus.failure,
        errorType: AttendanceErrorType.forbidden,
      ),
    ],
  );

  blocTest<StudentAttendanceSummaryBloc, StudentAttendanceSummaryState>(
    'emet [loading, failure(validation)] sur ValidationFailure (garde-fou ancre)',
    setUp: () => stubUseCase(const Left(ValidationFailure())),
    build: buildBloc,
    act: (bloc) => bloc.add(
      const StudentAttendanceSummaryRequested(
        studentId: '98f5',
        period: StatsPeriod.month,
      ),
    ),
    expect: () => [
      const StudentAttendanceSummaryState(
        status: StudentAttendanceSummaryStatus.loading,
      ),
      const StudentAttendanceSummaryState(
        status: StudentAttendanceSummaryStatus.failure,
        errorType: AttendanceErrorType.validation,
      ),
    ],
  );
}
