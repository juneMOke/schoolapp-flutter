import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/get_classroom_grid_usecase.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late GetClassroomGridUseCase useCase;

  const tTimetable = WeeklyTimetable(
    academicYearId: 'ay-1',
    classroomId: 'class-1',
    days: [],
    rows: [],
  );

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = GetClassroomGridUseCase(mockRepository);
  });

  test(
    'délègue au repository avec classroomId + année depuis les Params',
    () async {
      when(
        () => mockRepository.getClassroomGrid(any(), any()),
      ).thenAnswer((_) async => const Right(tTimetable));

      final result = await useCase(
        const GetClassroomGridParams(
          classroomId: 'class-1',
          academicYearId: 'ay-1',
        ),
      );

      result.fold((_) => fail('Right attendu'), (tt) => expect(tt, tTimetable));
      verify(
        () => mockRepository.getClassroomGrid('class-1', 'ay-1'),
      ).called(1);
    },
  );

  test('GetClassroomGridParams supporte l\'égalité (Equatable)', () {
    expect(
      const GetClassroomGridParams(classroomId: 'a', academicYearId: 'b'),
      const GetClassroomGridParams(classroomId: 'a', academicYearId: 'b'),
    );
  });
}
