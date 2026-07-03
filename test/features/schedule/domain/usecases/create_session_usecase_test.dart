import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_session_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/session.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_session_usecase.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late CreateSessionUseCase useCase;

  const tRequest = CreateSessionRequest(
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

  setUpAll(() => registerFallbackValue(tRequest));

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = CreateSessionUseCase(mockRepository);
  });

  test('délègue la requête au repository et renvoie Right', () async {
    when(
      () => mockRepository.createSession(any()),
    ).thenAnswer((_) async => const Right(tSession));

    final result = await useCase(tRequest);

    result.fold(
      (_) => fail('Right attendu'),
      (session) => expect(session, tSession),
    );
    verify(() => mockRepository.createSession(tRequest)).called(1);
  });

  test('propage la Failure du repository (409 conflit)', () async {
    when(
      () => mockRepository.createSession(any()),
    ).thenAnswer((_) async => const Left(ConflictFailure()));

    final result = await useCase(tRequest);

    expect(result, const Left<Failure, Session>(ConflictFailure()));
  });
}
