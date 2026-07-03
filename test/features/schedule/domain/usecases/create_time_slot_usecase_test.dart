import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/create_time_slot_request.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/create_time_slot_usecase.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late CreateTimeSlotUseCase useCase;

  const tRequest = CreateTimeSlotRequest(
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

  setUpAll(() => registerFallbackValue(tRequest));

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = CreateTimeSlotUseCase(mockRepository);
  });

  test('délègue la requête au repository et renvoie Right', () async {
    when(
      () => mockRepository.createTimeSlot(any()),
    ).thenAnswer((_) async => const Right(tSlot));

    final result = await useCase(tRequest);

    result.fold((_) => fail('Right attendu'), (slot) => expect(slot, tSlot));
    verify(() => mockRepository.createTimeSlot(tRequest)).called(1);
  });

  test('propage la Failure du repository', () async {
    when(
      () => mockRepository.createTimeSlot(any()),
    ).thenAnswer((_) async => const Left(ValidationFailure()));

    final result = await useCase(tRequest);

    expect(result, const Left<Failure, TimeSlot>(ValidationFailure()));
  });
}
