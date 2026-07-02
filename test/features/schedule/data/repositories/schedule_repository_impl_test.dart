import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/data/datasources/schedule_remote_data_source.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_session_request_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_time_slot_request_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/session_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/time_slot_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/timetable_cell_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/timetable_row_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/weekly_timetable_model.dart';
import 'package:school_app_flutter/features/schedule/data/repositories/schedule_repository_impl.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

class MockScheduleRemoteDataSource extends Mock
    implements ScheduleRemoteDataSource {}

void main() {
  late MockScheduleRemoteDataSource mockDataSource;
  late ScheduleRepositoryImpl repository;
  const auth = <String, dynamic>{'requiresAuth': true};

  const tCellModel = TimetableCellModel(
    sessionId: 'sess-1',
    coursId: 'cours-1',
    classroomId: 'class-1',
    classroomLabel: '6ème A',
    teacherId: 'teacher-1',
    teacherLabel: 'M. Dupont',
    subjectLabel: 'Maths',
    room: '101',
  );
  const tSlotModel = TimeSlotModel(
    id: 'ts-1',
    order: 1,
    startTime: '08:00:00',
    endTime: '08:50:00',
    label: 'P1',
  );
  const tTimetableModel = WeeklyTimetableModel(
    academicYearId: 'ay-1',
    teacherId: 'teacher-1',
    classroomId: null,
    days: ['MON', 'TUE'],
    rows: [
      TimetableRowModel(
        timeSlot: tSlotModel,
        cells: {'MON': tCellModel, 'TUE': null},
      ),
    ],
  );
  const tSessionModel = SessionModel(
    id: 'sess-1',
    academicYearId: 'ay-1',
    coursId: 'cours-1',
    timeSlotId: 'ts-1',
    day: 'MON',
    room: '101',
    teacherId: 'teacher-1',
    classroomId: 'class-1',
    teacherLabel: 'M. Dupont',
    classroomLabel: '6ème A',
    subjectLabel: 'Maths',
  );

  const tTimeSlotRequest = CreateTimeSlotRequest(
    order: 1,
    startTime: '08:00:00',
    endTime: '08:50:00',
    label: 'P1',
  );
  const tSessionRequest = CreateSessionRequest(
    coursId: 'cours-1',
    academicYearId: 'ay-1',
    day: Weekday.mon,
    timeSlotId: 'ts-1',
  );

  setUpAll(() {
    registerFallbackValue(
      const CreateTimeSlotRequestModel(
        order: 1,
        startTime: '08:00:00',
        endTime: '08:50:00',
      ),
    );
    registerFallbackValue(
      const CreateSessionRequestModel(
        coursId: 'c',
        academicYearId: 'ay',
        day: 'MON',
        timeSlotId: 'ts',
      ),
    );
  });

  setUp(() {
    mockDataSource = MockScheduleRemoteDataSource();
    repository = ScheduleRepositoryImpl(
      remoteDataSource: mockDataSource,
      requiredAuth: auth,
    );
  });

  group('getMyTimetable', () {
    test(
      'succès: mappe le modèle en entité + transmet auth et l\'année',
      () async {
        when(
          () => mockDataSource.getMyTimetable(any(), any()),
        ).thenAnswer((_) async => tTimetableModel);

        final result = await repository.getMyTimetable('ay-1');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Right attendu'), (tt) {
          expect(tt, tTimetableModel.toEntity());
          expect(tt.teacherId, 'teacher-1');
          expect(tt.rows.single.cellFor(Weekday.tue), isNull);
        });
        verify(() => mockDataSource.getMyTimetable(auth, 'ay-1')).called(1);
      },
    );

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(() => mockDataSource.getMyTimetable(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const NotFoundFailure('Resource not found'),
        ),
      );

      final result = await repository.getMyTimetable('ay-1');

      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.getMyTimetable(any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.getMyTimetable('ay-1');

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('Exception générique -> ServerFailure', () async {
      when(
        () => mockDataSource.getMyTimetable(any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.getMyTimetable('ay-1');

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });

  group('getClassroomGrid', () {
    test('succès: transmet auth, classroomId et l\'année', () async {
      when(
        () => mockDataSource.getClassroomGrid(any(), any(), any()),
      ).thenAnswer((_) async => tTimetableModel);

      final result = await repository.getClassroomGrid('class-1', 'ay-1');

      expect(result.isRight(), isTrue);
      verify(
        () => mockDataSource.getClassroomGrid(auth, 'class-1', 'ay-1'),
      ).called(1);
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.getClassroomGrid(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.getClassroomGrid('class-1', 'ay-1');

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });

  group('createTimeSlot', () {
    test(
      'succès: mappe le modèle en entité + transmet le corps converti',
      () async {
        when(
          () => mockDataSource.createTimeSlot(any(), any()),
        ).thenAnswer((_) async => tSlotModel);

        final result = await repository.createTimeSlot(tTimeSlotRequest);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Right attendu'),
          (slot) => expect(slot, tSlotModel.toEntity()),
        );

        final captured =
            verify(
                  () => mockDataSource.createTimeSlot(auth, captureAny()),
                ).captured.single
                as CreateTimeSlotRequestModel;
        expect(captured.toJson()['label'], 'P1');
      },
    );

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.createTimeSlot(any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.createTimeSlot(tTimeSlotRequest);

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });

  group('createSession', () {
    test(
      'succès: mappe le modèle en entité + transmet le corps converti',
      () async {
        when(
          () => mockDataSource.createSession(any(), any()),
        ).thenAnswer((_) async => tSessionModel);

        final result = await repository.createSession(tSessionRequest);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Right attendu'), (session) {
          expect(session, tSessionModel.toEntity());
          expect(session.day, Weekday.mon);
        });

        final captured =
            verify(
                  () => mockDataSource.createSession(auth, captureAny()),
                ).captured.single
                as CreateSessionRequestModel;
        expect(captured.toJson()['day'], 'MON');
        expect(captured.toJson().containsKey('room'), isFalse);
      },
    );

    test('409 -> ConflictFailure propagée (double-booking)', () async {
      when(() => mockDataSource.createSession(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const ConflictFailure('Conflict'),
        ),
      );

      final result = await repository.createSession(tSessionRequest);

      result.fold(
        (f) => expect(f, isA<ConflictFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('400 -> ValidationFailure propagée', () async {
      when(() => mockDataSource.createSession(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const ValidationFailure('Invalid request data'),
        ),
      );

      final result = await repository.createSession(tSessionRequest);

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });

  group('deleteSession', () {
    test('succès (204) -> Right(unit)', () async {
      when(
        () => mockDataSource.deleteSession(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.deleteSession('sess-1');

      expect(result.isRight(), isTrue);
      verify(() => mockDataSource.deleteSession(auth, 'sess-1')).called(1);
    });

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(() => mockDataSource.deleteSession(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const NotFoundFailure('Resource not found'),
        ),
      );

      final result = await repository.deleteSession('sess-1');

      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('Exception générique -> ServerFailure', () async {
      when(
        () => mockDataSource.deleteSession(any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.deleteSession('sess-1');

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });
}
