import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_cours_notation_detail_usecase.dart';

class MockCourseRepository extends Mock implements CourseRepository {}

const tCoursId = 'cours-1';

const tDetail = CoursNotationDetail(
  coursId: tCoursId,
  classroomId: 'class-1',
  brancheNom: 'Mathématiques',
  effectif: 30,
  periodes: [],
);

void main() {
  late MockCourseRepository mockRepository;
  late GetCoursNotationDetailUseCase useCase;

  setUp(() {
    mockRepository = MockCourseRepository();
    useCase = GetCoursNotationDetailUseCase(mockRepository);
  });

  test('délègue au repository avec le coursId et renvoie Right', () async {
    when(
      () => mockRepository.getCoursNotationDetail(any()),
    ).thenAnswer((_) async => const Right(tDetail));

    final result = await useCase(tCoursId);

    result.fold(
      (_) => fail('Right attendu'),
      (detail) => expect(detail, tDetail),
    );
    verify(() => mockRepository.getCoursNotationDetail(tCoursId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('propage la Failure du repository', () async {
    when(
      () => mockRepository.getCoursNotationDetail(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase(tCoursId);

    expect(result, const Left<Failure, CoursNotationDetail>(NotFoundFailure()));
  });
}
