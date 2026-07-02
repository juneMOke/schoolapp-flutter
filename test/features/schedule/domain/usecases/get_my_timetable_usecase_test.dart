import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_my_timetable_usecase.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late GetMyTimetableUseCase useCase;

  const tTimetable = WeeklyTimetable(
    academicYearId: 'ay-1',
    teacherId: 'teacher-1',
    days: [],
    rows: [],
  );

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = GetMyTimetableUseCase(mockRepository);
  });

  test('délègue au repository avec l\'année et renvoie Right', () async {
    when(
      () => mockRepository.getMyTimetable(any()),
    ).thenAnswer((_) async => const Right(tTimetable));

    final result = await useCase('ay-1');

    result.fold((_) => fail('Right attendu'), (tt) => expect(tt, tTimetable));
    verify(() => mockRepository.getMyTimetable('ay-1')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('propage la Failure du repository', () async {
    when(
      () => mockRepository.getMyTimetable(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase('ay-1');

    expect(result, const Left<Failure, WeeklyTimetable>(NotFoundFailure()));
  });
}
