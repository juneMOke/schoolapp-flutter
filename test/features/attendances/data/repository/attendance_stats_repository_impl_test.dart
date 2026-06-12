import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/data/models/student_attendance_summary_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/attendance_stats_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/attendance_stats_repository_impl.dart';

class MockAttendanceStatsRemoteDataSource extends Mock
    implements AttendanceStatsRemoteDataSource {}

void main() {
  late MockAttendanceStatsRemoteDataSource mockDataSource;
  late AttendanceStatsRepositoryImpl repository;
  const auth = <String, dynamic>{'requiresAuth': true};

  final tModel = StudentAttendanceSummaryModel(
    studentId: '98f5',
    firstName: 'John',
    lastName: 'Doe',
    academicYearName: '2025-2026',
    period: 'month',
    windowStart: DateTime(2026, 2, 1),
    windowEnd: DateTime(2026, 2, 28),
    presenceRate: 86.4,
    presentDays: 19,
    justifiedAbsenceDays: 2,
    unjustifiedAbsenceDays: 1,
    absences: const [],
  );

  setUp(() {
    mockDataSource = MockAttendanceStatsRemoteDataSource();
    repository = AttendanceStatsRepositoryImpl(
      remoteDataSource: mockDataSource,
      requiredAuth: auth,
    );
  });

  test(
    'succes: mappe le modele en entite + transmet period.apiValue',
    () async {
      when(
        () => mockDataSource.getStudentAttendanceSummary(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => tModel);

      final result = await repository.getStudentAttendanceSummary(
        studentId: '98f5',
        period: StatsPeriod.month,
        month: '2026-02',
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Right attendu'), (entity) {
        expect(entity.studentId, '98f5');
        expect(entity.period, StatsPeriod.month);
      });
      verify(
        () => mockDataSource.getStudentAttendanceSummary(
          auth,
          '98f5',
          'month',
          '2026-02',
          null,
        ),
      ).called(1);
    },
  );

  test('DioException portant une Failure -> Left(cette Failure)', () async {
    when(
      () => mockDataSource.getStudentAttendanceSummary(
        any(),
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const UnauthorizedFailure('Access forbidden'),
      ),
    );

    final result = await repository.getStudentAttendanceSummary(
      studentId: '98f5',
    );

    result.fold(
      (f) => expect(f, isA<UnauthorizedFailure>()),
      (_) => fail('Left attendu'),
    );
  });

  test('DioException sans Failure -> NetworkFailure', () async {
    when(
      () => mockDataSource.getStudentAttendanceSummary(
        any(),
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

    final result = await repository.getStudentAttendanceSummary(
      studentId: '98f5',
    );

    result.fold(
      (f) => expect(f, isA<NetworkFailure>()),
      (_) => fail('Left attendu'),
    );
  });
}
