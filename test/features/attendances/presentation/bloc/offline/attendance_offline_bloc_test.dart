import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_record.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/daily_attendance.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/local_attendance_rate.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/student_attendance_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_local_attendance_rate_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/get_student_attendance_stats_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/load_daily_attendance_usecase.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/record_daily_attendance_offline_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/attendance_offline_state.dart';

class MockLoadDailyAttendanceUseCase extends Mock
    implements LoadDailyAttendanceUseCase {}

class MockRecordDailyAttendanceOfflineUseCase extends Mock
    implements RecordDailyAttendanceOfflineUseCase {}

class MockGetLocalAttendanceRateUseCase extends Mock
    implements GetLocalAttendanceRateUseCase {}

class MockGetStudentAttendanceStatsUseCase extends Mock
    implements GetStudentAttendanceStatsUseCase {}

const tClassroomId = 'classroom-1';
const tAcademicYearId = 'year-1';
final tDate = DateTime(2026, 4, 30);

final tRecord = AttendanceRecord(
  studentId: 'student-1',
  studentFirstName: 'Aline',
  studentLastName: 'Mukendi',
  studentGender: StudentGender.female,
  classroomId: tClassroomId,
  academicYearId: tAcademicYearId,
  attendanceDate: tDate,
  present: true,
);

const tUpdate = AttendanceUpdate(
  studentId: 'student-1',
  studentFirstName: 'Aline',
  studentLastName: 'Mukendi',
  studentGender: StudentGender.female,
  present: false,
  absenceReason: AbsenceReason.sickness,
);

const tRate = LocalAttendanceRate(effectif: 20, absences: 3);

const tStats = StudentAttendanceStats(
  period: StatsPeriod.month,
  from: null,
  to: null,
  daysCalled: 10,
  entries: [],
  bootstrapComplete: true,
);

void main() {
  late MockLoadDailyAttendanceUseCase mockLoadDaily;
  late MockRecordDailyAttendanceOfflineUseCase mockRecordDaily;
  late MockGetLocalAttendanceRateUseCase mockGetRate;
  late MockGetStudentAttendanceStatsUseCase mockGetStudentStats;

  setUp(() {
    mockLoadDaily = MockLoadDailyAttendanceUseCase();
    mockRecordDaily = MockRecordDailyAttendanceOfflineUseCase();
    mockGetRate = MockGetLocalAttendanceRateUseCase();
    mockGetStudentStats = MockGetStudentAttendanceStatsUseCase();
  });

  AttendanceOfflineBloc buildBloc() => AttendanceOfflineBloc(
    loadDaily: mockLoadDaily,
    recordDaily: mockRecordDaily,
    getRate: mockGetRate,
    getStudentStats: mockGetStudentStats,
  );

  test('l\'état initial est AttendanceOfflineInitial', () {
    expect(buildBloc().state, const AttendanceOfflineInitial());
  });

  group('LoadDailyAttendanceRequested', () {
    blocTest<AttendanceOfflineBloc, AttendanceOfflineState>(
      'émet [loading, loaded] avec la liste d\'appel locale',
      setUp: () {
        when(
          () => mockLoadDaily(
            classroomId: tClassroomId,
            date: tDate,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer(
          (_) async => Right(DailyAttendance(taken: true, records: [tRecord])),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        LoadDailyAttendanceRequested(
          classroomId: tClassroomId,
          date: tDate,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => [
        const AttendanceOfflineLoading(),
        AttendanceOfflineLoaded(
          DailyAttendance(taken: true, records: [tRecord]),
        ),
      ],
    );

    blocTest<AttendanceOfflineBloc, AttendanceOfflineState>(
      'émet [loading, error] quand le chargement échoue',
      setUp: () {
        when(
          () => mockLoadDaily(
            classroomId: tClassroomId,
            date: tDate,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Left(StorageFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        LoadDailyAttendanceRequested(
          classroomId: tClassroomId,
          date: tDate,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => [
        const AttendanceOfflineLoading(),
        const AttendanceOfflineError('Erreur d\'accès à la base locale.'),
      ],
    );
  });

  group('RecordDailyAttendanceRequested', () {
    blocTest<AttendanceOfflineBloc, AttendanceOfflineState>(
      'émet [recording, pendingSync] après écriture locale + outbox',
      setUp: () {
        when(
          () => mockRecordDaily(
            classroomId: tClassroomId,
            date: tDate,
            academicYearId: tAcademicYearId,
            updates: [tUpdate],
          ),
        ).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        RecordDailyAttendanceRequested(
          classroomId: tClassroomId,
          date: tDate,
          academicYearId: tAcademicYearId,
          updates: const [tUpdate],
        ),
      ),
      expect: () => [
        const AttendanceOfflineRecording(),
        const AttendanceOfflinePendingSync(),
      ],
      verify: (_) {
        verify(
          () => mockRecordDaily(
            classroomId: tClassroomId,
            date: tDate,
            academicYearId: tAcademicYearId,
            updates: [tUpdate],
          ),
        ).called(1);
      },
    );

    blocTest<AttendanceOfflineBloc, AttendanceOfflineState>(
      'émet [recording, error] quand l\'écriture échoue',
      setUp: () {
        when(
          () => mockRecordDaily(
            classroomId: tClassroomId,
            date: tDate,
            academicYearId: tAcademicYearId,
            updates: [tUpdate],
          ),
        ).thenAnswer((_) async => const Left(StorageFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        RecordDailyAttendanceRequested(
          classroomId: tClassroomId,
          date: tDate,
          academicYearId: tAcademicYearId,
          updates: const [tUpdate],
        ),
      ),
      expect: () => [
        const AttendanceOfflineRecording(),
        const AttendanceOfflineError('Erreur d\'accès à la base locale.'),
      ],
    );
  });

  group('LoadLocalRateRequested', () {
    blocTest<AttendanceOfflineBloc, AttendanceOfflineState>(
      'émet [loading, rateLoaded] avec le taux dérivé localement',
      setUp: () {
        when(
          () => mockGetRate(
            classroomId: tClassroomId,
            date: tDate,
            academicYearId: tAcademicYearId,
          ),
        ).thenAnswer((_) async => const Right(tRate));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        LoadLocalRateRequested(
          classroomId: tClassroomId,
          date: tDate,
          academicYearId: tAcademicYearId,
        ),
      ),
      expect: () => [
        const AttendanceOfflineLoading(),
        const AttendanceOfflineRateLoaded(tRate),
      ],
    );
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
