import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_session_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_time_slot_usecase.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/delete_session_usecase.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_edit_bloc.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_edit_event.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_edit_state.dart';
import 'package:school_app_flutter/features/schedule/presentation/bloc/schedule_error_type.dart';

class MockCreateTimeSlotUseCase extends Mock implements CreateTimeSlotUseCase {}

class MockCreateSessionUseCase extends Mock implements CreateSessionUseCase {}

class MockDeleteSessionUseCase extends Mock implements DeleteSessionUseCase {}

void main() {
  late MockCreateTimeSlotUseCase mockCreateTimeSlot;
  late MockCreateSessionUseCase mockCreateSession;
  late MockDeleteSessionUseCase mockDeleteSession;

  const tTimeSlotRequest = CreateTimeSlotRequest(
    order: 1,
    startTime: '08:00:00',
    endTime: '08:50:00',
  );
  const tSlot = TimeSlot(
    id: 'ts-1',
    order: 1,
    startTime: '08:00:00',
    endTime: '08:50:00',
  );
  const tSessionRequest = CreateSessionRequest(
    coursId: 'cours-1',
    academicYearId: 'ay-1',
    day: Weekday.mon,
    timeSlotId: 'ts-1',
  );
  const tSession = Session(
    id: 'sess-1',
    academicYearId: 'ay-1',
    coursId: 'cours-1',
    timeSlotId: 'ts-1',
    day: Weekday.mon,
    teacherId: 'teacher-1',
    classroomId: 'class-1',
    teacherLabel: 'M. Dupont',
    classroomLabel: '6ème A',
    subjectLabel: 'Maths',
  );

  setUpAll(() {
    registerFallbackValue(tTimeSlotRequest);
    registerFallbackValue(tSessionRequest);
  });

  late Completer<Either<Failure, Session>> completer;

  setUp(() {
    mockCreateTimeSlot = MockCreateTimeSlotUseCase();
    mockCreateSession = MockCreateSessionUseCase();
    mockDeleteSession = MockDeleteSessionUseCase();
  });

  ScheduleEditBloc buildBloc() => ScheduleEditBloc(
    createTimeSlot: mockCreateTimeSlot,
    createSession: mockCreateSession,
    deleteSession: mockDeleteSession,
  );

  test('état initial', () {
    expect(buildBloc().state, const ScheduleEditState());
  });

  group('TimeSlotCreated', () {
    blocTest<ScheduleEditBloc, ScheduleEditState>(
      'submitting puis success portant le créneau créé',
      setUp: () {
        when(
          () => mockCreateTimeSlot(any()),
        ).thenAnswer((_) async => const Right(tSlot));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TimeSlotCreated(request: tTimeSlotRequest)),
      expect: () => const [
        ScheduleEditState(status: ScheduleEditStatus.submitting),
        ScheduleEditState(
          status: ScheduleEditStatus.success,
          lastCreatedTimeSlot: tSlot,
        ),
      ],
      verify: (_) {
        verify(() => mockCreateTimeSlot(tTimeSlotRequest)).called(1);
      },
    );
  });

  group('SessionCreated', () {
    blocTest<ScheduleEditBloc, ScheduleEditState>(
      'submitting puis success portant la séance créée',
      setUp: () {
        when(
          () => mockCreateSession(any()),
        ).thenAnswer((_) async => const Right(tSession));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionCreated(request: tSessionRequest)),
      expect: () => const [
        ScheduleEditState(status: ScheduleEditStatus.submitting),
        ScheduleEditState(
          status: ScheduleEditStatus.success,
          lastCreatedSession: tSession,
        ),
      ],
    );

    blocTest<ScheduleEditBloc, ScheduleEditState>(
      '409 -> errorType conflict (double-booking)',
      setUp: () {
        when(
          () => mockCreateSession(any()),
        ).thenAnswer((_) async => const Left(ConflictFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionCreated(request: tSessionRequest)),
      expect: () => const [
        ScheduleEditState(status: ScheduleEditStatus.submitting),
        ScheduleEditState(
          status: ScheduleEditStatus.failure,
          errorType: ScheduleErrorType.conflict,
          errorMessage: 'Conflict',
        ),
      ],
    );

    blocTest<ScheduleEditBloc, ScheduleEditState>(
      '400 -> errorType validation (cours sans enseignant)',
      setUp: () {
        when(
          () => mockCreateSession(any()),
        ).thenAnswer((_) async => const Left(ValidationFailure()));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionCreated(request: tSessionRequest)),
      expect: () => const [
        ScheduleEditState(status: ScheduleEditStatus.submitting),
        ScheduleEditState(
          status: ScheduleEditStatus.failure,
          errorType: ScheduleErrorType.validation,
          errorMessage: 'Invalid request data',
        ),
      ],
    );
  });

  group('SessionDeleted', () {
    blocTest<ScheduleEditBloc, ScheduleEditState>(
      'submitting puis success (aucune donnée créée)',
      setUp: () {
        when(
          () => mockDeleteSession(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionDeleted(sessionId: 'sess-1')),
      expect: () => const [
        ScheduleEditState(status: ScheduleEditStatus.submitting),
        ScheduleEditState(status: ScheduleEditStatus.success),
      ],
      verify: (_) {
        verify(() => mockDeleteSession('sess-1')).called(1);
      },
    );
  });

  group('garde anti-double-envoi', () {
    blocTest<ScheduleEditBloc, ScheduleEditState>(
      'ignore une soumission tant qu\'un envoi est en cours',
      seed: () =>
          const ScheduleEditState(status: ScheduleEditStatus.submitting),
      build: buildBloc,
      act: (bloc) => bloc.add(const SessionCreated(request: tSessionRequest)),
      expect: () => const <ScheduleEditState>[],
      verify: (_) {
        verifyNever(() => mockCreateSession(any()));
      },
    );

    blocTest<ScheduleEditBloc, ScheduleEditState>(
      'deux SessionCreated rapprochés -> un seul appel usecase',
      setUp: () {
        completer = Completer<Either<Failure, Session>>();
        when(
          () => mockCreateSession(any()),
        ).thenAnswer((_) => completer.future);
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const SessionCreated(request: tSessionRequest));
        bloc.add(const SessionCreated(request: tSessionRequest)); // ignoré
        // On laisse les deux events se faire traiter (le 1er reste en vol sur
        // la future non complétée, le 2e tombe dans la garde) AVANT de
        // compléter l'appel.
        await Future<void>.delayed(Duration.zero);
        completer.complete(const Right(tSession));
      },
      expect: () => const [
        ScheduleEditState(status: ScheduleEditStatus.submitting),
        ScheduleEditState(
          status: ScheduleEditStatus.success,
          lastCreatedSession: tSession,
        ),
      ],
      verify: (_) {
        verify(() => mockCreateSession(tSessionRequest)).called(1);
      },
    );
  });

  group('ScheduleEditReset', () {
    blocTest<ScheduleEditBloc, ScheduleEditState>(
      'réinitialise vers l\'état initial',
      seed: () => const ScheduleEditState(
        status: ScheduleEditStatus.success,
        lastCreatedSession: tSession,
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const ScheduleEditReset()),
      expect: () => const [ScheduleEditState()],
    );
  });
}
