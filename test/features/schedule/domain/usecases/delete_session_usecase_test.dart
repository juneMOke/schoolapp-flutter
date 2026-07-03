import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:school_app_flutter/features/schedule/domain/usecases/delete_session_usecase.dart';

class MockScheduleRepository extends Mock implements ScheduleRepository {}

void main() {
  late MockScheduleRepository mockRepository;
  late DeleteSessionUseCase useCase;

  setUp(() {
    mockRepository = MockScheduleRepository();
    useCase = DeleteSessionUseCase(mockRepository);
  });

  test('délègue au repository et renvoie Right(unit)', () async {
    when(
      () => mockRepository.deleteSession(any()),
    ).thenAnswer((_) async => const Right(unit));

    final result = await useCase('sess-1');

    expect(result, const Right<Failure, Unit>(unit));
    verify(() => mockRepository.deleteSession('sess-1')).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('propage la Failure du repository', () async {
    when(
      () => mockRepository.deleteSession(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase('sess-1');

    expect(result, const Left<Failure, Unit>(NotFoundFailure()));
  });
}
