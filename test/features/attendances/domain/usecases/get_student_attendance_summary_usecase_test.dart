import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/attendance_stats_repository.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/get_student_attendance_summary_usecase.dart';

class MockAttendanceStatsRepository extends Mock
    implements AttendanceStatsRepository {}

void main() {
  late MockAttendanceStatsRepository mockRepository;
  late GetStudentAttendanceSummaryUseCase usecase;

  final tSummary = StudentAttendanceSummary(
    studentId: '98f5',
    firstName: 'John',
    lastName: 'Doe',
    academicYearName: '2025-2026',
    period: StatsPeriod.year,
    windowStart: DateTime(2025, 9, 1),
    windowEnd: DateTime(2026, 6, 30),
    presenceRate: 90,
    presentDays: 100,
    justifiedAbsenceDays: 5,
    unjustifiedAbsenceDays: 3,
    absences: const [],
  );

  setUpAll(() => registerFallbackValue(StatsPeriod.year));

  setUp(() {
    mockRepository = MockAttendanceStatsRepository();
    usecase = GetStudentAttendanceSummaryUseCase(mockRepository);
  });

  test(
    'period=month sans month -> ValidationFailure (aucun appel repo)',
    () async {
      final result = await usecase(
        studentId: '98f5',
        period: StatsPeriod.month,
      );

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Left attendu'),
      );
      verifyNever(
        () => mockRepository.getStudentAttendanceSummary(
          studentId: any(named: 'studentId'),
          period: any(named: 'period'),
          month: any(named: 'month'),
          week: any(named: 'week'),
        ),
      );
    },
  );

  test('period=week sans week -> ValidationFailure', () async {
    final result = await usecase(studentId: '98f5', period: StatsPeriod.week);

    result.fold(
      (f) => expect(f, isA<ValidationFailure>()),
      (_) => fail('Left attendu'),
    );
  });

  test('parametres valides -> delegue au repository', () async {
    when(
      () => mockRepository.getStudentAttendanceSummary(
        studentId: any(named: 'studentId'),
        period: any(named: 'period'),
        month: any(named: 'month'),
        week: any(named: 'week'),
      ),
    ).thenAnswer((_) async => Right(tSummary));

    final result = await usecase(
      studentId: '98f5',
      period: StatsPeriod.month,
      month: '2026-02',
    );

    expect(result.isRight(), isTrue);
    verify(
      () => mockRepository.getStudentAttendanceSummary(
        studentId: '98f5',
        period: StatsPeriod.month,
        month: '2026-02',
        week: null,
      ),
    ).called(1);
  });
}
