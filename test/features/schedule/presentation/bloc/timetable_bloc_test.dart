import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_classroom_grid_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_my_timetable_usecase.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_bloc.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_event.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/timetable_state.dart';

class MockGetMyTimetableUseCase extends Mock implements GetMyTimetableUseCase {}

class MockGetClassroomGridUseCase extends Mock
    implements GetClassroomGridUseCase {}

/// Failure non mappée explicitement : exerce la branche par défaut du switch.
class _UnmappedFailure extends Failure {
  const _UnmappedFailure() : super('unmapped');
}

void main() {
  late MockGetMyTimetableUseCase mockGetMyTimetable;
  late MockGetClassroomGridUseCase mockGetClassroomGrid;

  // Matrice avec une case occupée (MON) et une libre (TUE = null).
  const tTimetable = WeeklyTimetable(
    academicYearId: 'ay-1',
    teacherId: 'teacher-1',
    days: [Weekday.mon, Weekday.tue],
    rows: [
      TimetableRow(
        timeSlot: TimeSlot(
          id: 'ts-1',
          order: 1,
          startTime: '08:00:00',
          endTime: '08:50:00',
        ),
        cells: {
          Weekday.mon: TimetableCell(
            sessionId: 'sess-1',
            coursId: 'cours-1',
            classroomId: 'class-1',
            classroomLabel: '6ème A',
            teacherId: 'teacher-1',
            teacherLabel: 'M. Dupont',
            subjectLabel: 'Maths',
          ),
          Weekday.tue: null,
        },
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(
      const GetClassroomGridParams(classroomId: 'x', academicYearId: 'y'),
    );
  });

  setUp(() {
    mockGetMyTimetable = MockGetMyTimetableUseCase();
    mockGetClassroomGrid = MockGetClassroomGridUseCase();
  });

  TimetableBloc buildBloc() => TimetableBloc(
    getMyTimetable: mockGetMyTimetable,
    getClassroomGrid: mockGetClassroomGrid,
  );

  test('état initial', () {
    expect(buildBloc().state, const TimetableState());
  });

  group('TimetableRequested', () {
    blocTest<TimetableBloc, TimetableState>(
      'loading puis success ; les cases null sont normales (pas une erreur)',
      setUp: () {
        when(
          () => mockGetMyTimetable(any()),
        ).thenAnswer((_) async => const Right(tTimetable));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TimetableRequested(academicYearId: 'ay-1')),
      expect: () => const [
        TimetableState(status: TimetableStatus.loading),
        TimetableState(status: TimetableStatus.success, timetable: tTimetable),
      ],
      verify: (_) {
        verify(() => mockGetMyTimetable('ay-1')).called(1);
      },
    );

    final cases = <(Failure, ScheduleErrorType)>[
      (const NetworkFailure(), ScheduleErrorType.network),
      (const NotFoundFailure(), ScheduleErrorType.notFound),
      (const ValidationFailure(), ScheduleErrorType.validation),
      (const UnauthorizedFailure(), ScheduleErrorType.forbidden),
      (const InvalidCredentialsFailure(), ScheduleErrorType.invalidCredentials),
      (const ConflictFailure(), ScheduleErrorType.conflict),
      (const ServerFailure(), ScheduleErrorType.server),
      (const StorageFailure(), ScheduleErrorType.storage),
      (const AuthFailure(), ScheduleErrorType.auth),
      (const _UnmappedFailure(), ScheduleErrorType.unknown),
    ];

    for (final (failure, errorType) in cases) {
      blocTest<TimetableBloc, TimetableState>(
        'mappe ${failure.runtimeType} -> $errorType',
        setUp: () {
          when(
            () => mockGetMyTimetable(any()),
          ).thenAnswer((_) async => Left(failure));
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const TimetableRequested(academicYearId: 'ay-1')),
        expect: () => [
          const TimetableState(status: TimetableStatus.loading),
          TimetableState(status: TimetableStatus.failure, errorType: errorType),
        ],
      );
    }
  });

  group('ClassroomGridRequested', () {
    blocTest<TimetableBloc, TimetableState>(
      'loading puis success + transmet les bons Params',
      setUp: () {
        when(
          () => mockGetClassroomGrid(any()),
        ).thenAnswer((_) async => const Right(tTimetable));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ClassroomGridRequested(
          classroomId: 'class-1',
          academicYearId: 'ay-1',
        ),
      ),
      expect: () => const [
        TimetableState(status: TimetableStatus.loading),
        TimetableState(status: TimetableStatus.success, timetable: tTimetable),
      ],
      verify: (_) {
        verify(
          () => mockGetClassroomGrid(
            const GetClassroomGridParams(
              classroomId: 'class-1',
              academicYearId: 'ay-1',
            ),
          ),
        ).called(1);
      },
    );
  });
}
