import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/focus_entete.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/synthese.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/get_resultat_focus_usecase.dart';

class MockResultatsRepository extends Mock implements ResultatsRepository {}

const _tFocus = ResultatFocus(
  classroomId: 'c',
  periodeScolaireId: 'p',
  periodeOrdre: 1,
  entete: FocusEntete(studentId: 's', nom: 'D', prenom: 'J', nbClasses: 10),
  progression: [],
  topMatieres: [],
  bottomMatieres: [],
  synthese: Synthese(nbClasses: 10),
);

void main() {
  late MockResultatsRepository repo;
  late GetResultatFocusUseCase useCase;

  setUp(() {
    repo = MockResultatsRepository();
    useCase = GetResultatFocusUseCase(repo);
  });

  test('délègue au repository avec les params et renvoie Right', () async {
    when(
      () => repo.getResultatFocus(any(), any(), any()),
    ).thenAnswer((_) async => const Right(_tFocus));

    final result = await useCase(
      const GetResultatFocusParams(
        classroomId: 'c',
        periodeScolaireId: 'p',
        studentId: 's',
      ),
    );

    result.fold((_) => fail('Right attendu'), (v) => expect(v, _tFocus));
    verify(() => repo.getResultatFocus('c', 'p', 's')).called(1);
    verifyNoMoreInteractions(repo);
  });

  test('propage la Failure du repository', () async {
    when(
      () => repo.getResultatFocus(any(), any(), any()),
    ).thenAnswer((_) async => const Left(UnauthorizedFailure()));

    final result = await useCase(
      const GetResultatFocusParams(
        classroomId: 'c',
        periodeScolaireId: 'p',
        studentId: 's',
      ),
    );

    expect(result, const Left<Failure, ResultatFocus>(UnauthorizedFailure()));
  });
}
