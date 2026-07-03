import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/domain/repositories/resultats_repository.dart';
import 'package:school_app_flutter/features/resultats/domain/usecases/search_roster_usecase.dart';

class MockResultatsRepository extends Mock implements ResultatsRepository {}

const _tMember = ClassroomMember(
  id: 'm',
  studentId: 's',
  classroomId: 'c',
  academicYearId: 'ay',
  studentFirstName: 'J',
  studentLastName: 'D',
  studentGender: ClassroomMemberGender.female,
);

void main() {
  late MockResultatsRepository repo;
  late SearchRosterUseCase useCase;

  setUp(() {
    repo = MockResultatsRepository();
    useCase = SearchRosterUseCase(repo);
  });

  test('délègue au repository avec les params et renvoie Right', () async {
    when(
      () => repo.searchRoster(any(), any(), any(), any(), any()),
    ).thenAnswer((_) async => const Right([_tMember]));

    final result = await useCase(
      const SearchRosterParams(
        classroomId: 'c',
        academicYearId: 'ay',
        nom: 'D',
      ),
    );

    result.fold(
      (_) => fail('Right attendu'),
      (v) => expect(v, const [_tMember]),
    );
    verify(() => repo.searchRoster('c', 'ay', 'D', null, null)).called(1);
    verifyNoMoreInteractions(repo);
  });

  test('propage la Failure du repository', () async {
    when(
      () => repo.searchRoster(any(), any(), any(), any(), any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(
      const SearchRosterParams(classroomId: 'c', academicYearId: 'ay'),
    );

    expect(
      result,
      const Left<Failure, List<ClassroomMember>>(NetworkFailure()),
    );
  });
}
