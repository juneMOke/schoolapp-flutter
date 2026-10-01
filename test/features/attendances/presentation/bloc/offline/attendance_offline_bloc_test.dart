import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_student_attendance_stats_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';

class MockGetStudentAttendanceStatsUseCase extends Mock
    implements GetStudentAttendanceStatsUseCase {}

const tAcademicYearId = 'year-1';

const tStats = StudentAttendanceStats(
  period: StatsPeriod.month,
  from: null,
  to: null,
  daysCalled: 10,
  entries: [],
  bootstrapComplete: true,
);

void main() {
  late MockGetStudentAttendanceStatsUseCase mockGetStudentStats;

  setUp(() {
    mockGetStudentStats = MockGetStudentAttendanceStatsUseCase();
  });

  AttendanceOfflineBloc buildBloc() =>
      AttendanceOfflineBloc(getStudentStats: mockGetStudentStats);

  test('l\'état initial est AttendanceOfflineInitial', () {
    expect(buildBloc().state, const AttendanceOfflineInitial());
  });

  group('LoadStudentStatsRequested', () {
    final tReference = DateTime(2026, 5, 15);

    blocTest<AttendanceOfflineBloc, AttendanceOfflineState>(
      'émet [loading, statsLoaded] avec les statistiques calculées localement',
      setUp: () {
        when(
          () => mockGetStudentStats(
            studentId: 'student-1',
            academicYearId: tAcademicYearId,
            period: StatsPeriod.month,
            reference: tReference,
          ),
        ).thenAnswer((_) async => const Right(tStats));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        LoadStudentStatsRequested(
          studentId: 'student-1',
          academicYearId: tAcademicYearId,
          period: StatsPeriod.month,
          reference: tReference,
        ),
      ),
      expect: () => [
        const AttendanceOfflineLoading(),
        const AttendanceOfflineStatsLoaded(tStats),
      ],
    );

    blocTest<AttendanceOfflineBloc, AttendanceOfflineState>(
      'émet [loading, error] quand le calcul local échoue',
      setUp: () {
        when(
          () => mockGetStudentStats(
            studentId: 'student-1',
            academicYearId: tAcademicYearId,
            period: StatsPeriod.month,
            reference: tReference,
          ),
        ).thenAnswer((_) async => const Left(StorageFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        LoadStudentStatsRequested(
          studentId: 'student-1',
          academicYearId: tAcademicYearId,
          period: StatsPeriod.month,
          reference: tReference,
        ),
      ),
      expect: () => [
        const AttendanceOfflineLoading(),
        const AttendanceOfflineError('Erreur d\'accès à la base locale.'),
      ],
    );
  });
}
