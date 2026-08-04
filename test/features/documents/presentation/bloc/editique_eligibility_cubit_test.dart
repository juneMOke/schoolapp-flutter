import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/is_student_known_to_server_use_case.dart';

class _MockIsStudentKnownToServerUseCase extends Mock
    implements IsStudentKnownToServerUseCase {}

void main() {
  late _MockIsStudentKnownToServerUseCase useCase;

  setUp(() => useCase = _MockIsStudentKnownToServerUseCase());

  blocTest<EditiqueEligibilityCubit, EditiqueEligibilityState>(
    'ouvre l action quand le serveur connaît déjà l élève',
    setUp: () =>
        when(() => useCase(any())).thenAnswer((_) async => const Right(true)),
    build: () => EditiqueEligibilityCubit(useCase),
    act: (cubit) => cubit.resolveForStudent('stu-1'),
    expect: () => [
      isA<EditiqueEligibilityState>().having(
        (s) => s.status,
        'status',
        EditiqueEligibilityStatus.resolving,
      ),
      isA<EditiqueEligibilityState>()
          .having((s) => s.isEligible, 'isEligible', isTrue)
          .having((s) => s.isBlocked, 'isBlocked', isFalse),
    ],
  );

  blocTest<EditiqueEligibilityCubit, EditiqueEligibilityState>(
    'bloque l action quand l élève n est pas encore connu du serveur',
    setUp: () =>
        when(() => useCase(any())).thenAnswer((_) async => const Right(false)),
    build: () => EditiqueEligibilityCubit(useCase),
    act: (cubit) => cubit.resolveForStudent('stu-1'),
    skip: 1,
    expect: () => [
      isA<EditiqueEligibilityState>()
          .having((s) => s.isEligible, 'isEligible', isFalse)
          .having((s) => s.isBlocked, 'isBlocked', isTrue),
    ],
  );

  // Fail-closed : une lecture locale en échec ne doit jamais rouvrir l'action
  // sur une supposition. Mieux vaut éteindre une action légitime que d'envoyer
  // l'utilisateur vers un 404 — ou, sur une pièce non archivée, vers un numéro
  // de séquence brûlé pour rien.
  blocTest<EditiqueEligibilityCubit, EditiqueEligibilityState>(
    'bloque l action quand la lecture locale échoue',
    setUp: () => when(
      () => useCase(any()),
    ).thenAnswer((_) async => const Left(StorageFailure('base illisible'))),
    build: () => EditiqueEligibilityCubit(useCase),
    act: (cubit) => cubit.resolveForStudent('stu-1'),
    skip: 1,
    expect: () => [
      isA<EditiqueEligibilityState>().having(
        (s) => s.isBlocked,
        'isBlocked',
        isTrue,
      ),
    ],
  );

  test('part éteint : rien n est affirmé avant résolution', () {
    final cubit = EditiqueEligibilityCubit(useCase);

    expect(cubit.state.isEligible, isFalse);
    expect(cubit.state.isBlocked, isFalse);

    cubit.close();
  });
}
