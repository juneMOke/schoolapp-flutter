import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/data/models/attendance_overview_response_model/attendance_overview_response_model.dart';
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

  group('getAttendanceOverview', () {
    Map<String, dynamic> buildJson() => <String, dynamic>{
      'context': <String, dynamic>{
        'schoolYear': '2025-2026',
        'period': 'year',
        'periodStart': '2025-09-01',
        'periodEnd': '2026-06-30',
        'generatedAt': '2026-02-15T08:30:00Z',
      },
      'kpis': <String, dynamic>{
        'presenceRate': 92.5,
        'justifiedAbsenceRate': 5.0,
        'unjustifiedAbsenceRate': 2.5,
        'recordedDays': 180,
        'presentDays': 166,
        'justifiedAbsenceDays': 9,
        'unjustifiedAbsenceDays': 5,
      },
      'evolution': <String, dynamic>{
        'granularity': 'month',
        'currentBucketIndex': 5,
        'buckets': const <dynamic>[],
      },
    };

    final tOverviewModel = AttendanceOverviewResponseModel.fromJson(
      buildJson(),
    );

    test(
      'succes: mappe le modele en entite + transmet period.apiValue (year par defaut)',
      () async {
        when(
          () =>
              mockDataSource.getAttendanceOverview(any(), any(), any(), any()),
        ).thenAnswer((_) async => tOverviewModel);

        final result = await repository.getAttendanceOverview();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Right attendu'), (entity) {
          expect(entity, tOverviewModel.toEntity());
          // Champs concrets decodes depuis le JSON fixture (pin du toEntity).
          expect(entity.context.period, 'year');
          expect(entity.context.schoolYear, '2025-2026');
          expect(entity.kpis.presenceRate, 92.5);
          expect(entity.kpis.presentDays, 166);
        });
        verify(
          () => mockDataSource.getAttendanceOverview(auth, 'year', null, null),
        ).called(1);
      },
    );

    test(
      'succes: period.apiValue=month transmet month et period=month',
      () async {
        when(
          () =>
              mockDataSource.getAttendanceOverview(any(), any(), any(), any()),
        ).thenAnswer((_) async => tOverviewModel);

        final result = await repository.getAttendanceOverview(
          period: StatsPeriod.month,
          month: '2026-02',
        );

        expect(result.isRight(), isTrue);
        verify(
          () => mockDataSource.getAttendanceOverview(
            auth,
            'month',
            '2026-02',
            null,
          ),
        ).called(1);
      },
    );

    test('succes: period.apiValue=week transmet week et period=week', () async {
      when(
        () => mockDataSource.getAttendanceOverview(any(), any(), any(), any()),
      ).thenAnswer((_) async => tOverviewModel);

      final result = await repository.getAttendanceOverview(
        period: StatsPeriod.week,
        week: '2026-W07',
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockDataSource.getAttendanceOverview(
          auth,
          'week',
          null,
          '2026-W07',
        ),
      ).called(1);
    });

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(
        () => mockDataSource.getAttendanceOverview(any(), any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const ServerFailure('Server error occurred'),
        ),
      );

      final result = await repository.getAttendanceOverview();

      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f, const ServerFailure('Server error occurred'));
      }, (_) => fail('Left attendu'));
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.getAttendanceOverview(any(), any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.getAttendanceOverview();

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('FormatException -> ServerFailure(payload invalide)', () async {
      when(
        () => mockDataSource.getAttendanceOverview(any(), any(), any(), any()),
      ).thenThrow(const FormatException('boom'));

      final result = await repository.getAttendanceOverview();

      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f, const ServerFailure('Invalid attendance overview payload'));
      }, (_) => fail('Left attendu'));
    });

    test('Exception generique -> ServerFailure(erreur inattendue)', () async {
      when(
        () => mockDataSource.getAttendanceOverview(any(), any(), any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.getAttendanceOverview();

      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f, const ServerFailure('Unexpected error occurred'));
      }, (_) => fail('Left attendu'));
    });
  });
}
