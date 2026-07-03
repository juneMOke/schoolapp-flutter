import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe_stats.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultats_classe_usecase.dart';

class MockResultatsRepository extends Mock implements ResultatsRepository {}

const _tClasse = ResultatsClasse(
  classroomId: 'c',
  periodeScolaireId: 'p',
  periodeOrdre: 1,
  sousPeriodes: [],
  stats: ResultatsClasseStats(
    effectif: 1,
    seuil: 50,
    reussites: 0,
    echecs: 0,
    nonClasses: 0,
  ),
  lignes: [],
);

void main() {
  late MockResultatsRepository repo;
  late GetResultatsClasseUseCase useCase;

  setUp(() {
    repo = MockResultatsRepository();
    useCase = GetResultatsClasseUseCase(repo);
  });

  test('délègue au repository avec les params et renvoie Right', () async {
    when(
      () => repo.getResultatsClasse(any(), any(), any()),
    ).thenAnswer((_) async => const Right(_tClasse));

    final result = await useCase(
      const GetResultatsClasseParams(
        classroomId: 'c',
        periodeScolaireId: 'p',
        seuil: 60,
      ),
    );

    result.fold((_) => fail('Right attendu'), (v) => expect(v, _tClasse));
    verify(() => repo.getResultatsClasse('c', 'p', 60)).called(1);
    verifyNoMoreInteractions(repo);
  });

  test('propage la Failure du repository', () async {
    when(
      () => repo.getResultatsClasse(any(), any(), any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase(
      const GetResultatsClasseParams(classroomId: 'c', periodeScolaireId: 'p'),
    );

    expect(result, const Left<Failure, ResultatsClasse>(NotFoundFailure()));
  });
}
