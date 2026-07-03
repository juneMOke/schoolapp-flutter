// `dartz` et `flutter_test` exportent un type `Evaluation` : on les masque au
// profit de notre entité domaine.
import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/create_evaluation_usecase.dart';

class MockCourseRepository extends Mock implements CourseRepository {}

void main() {
  late MockCourseRepository mockRepository;
  late CreateEvaluationUseCase useCase;

  const tCoursId = 'cours-1';
  final tDate = DateTime(2025, 11, 10);
  final tRequest = CreateEvaluationRequest.examen(
    date: tDate,
    maxPoints: 20,
    periodeScolaireId: 'periode-1',
  );
  final tEvaluation = Evaluation(
    id: 'ev-1',
    coursId: tCoursId,
    type: TypeEvaluation.examen,
    date: tDate,
    maxPoints: 20,
    poids: 1,
    periodeScolaireId: 'periode-1',
  );

  setUpAll(() {
    registerFallbackValue(tRequest);
  });

  setUp(() {
    mockRepository = MockCourseRepository();
    useCase = CreateEvaluationUseCase(mockRepository);
  });

  test('délègue au repository et renvoie Right(Evaluation)', () async {
    when(
      () => mockRepository.createEvaluation(any(), any()),
    ).thenAnswer((_) async => Right(tEvaluation));

    final result = await useCase(tCoursId, tRequest);

    expect(result, Right<Failure, Evaluation>(tEvaluation));
    verify(() => mockRepository.createEvaluation(tCoursId, tRequest)).called(1);
  });

  test('propage le Left du repository', () async {
    when(
      () => mockRepository.createEvaluation(any(), any()),
    ).thenAnswer((_) async => const Left(ValidationFailure()));

    final result = await useCase(tCoursId, tRequest);

    expect(result, const Left<Failure, Evaluation>(ValidationFailure()));
  });
}
