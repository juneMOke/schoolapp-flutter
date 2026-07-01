import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/notation_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';

class MockNotationRepository extends Mock implements NotationRepository {}

void main() {
  late MockNotationRepository mockRepository;
  late GetNotesElevesUseCase useCase;

  const tEvaluationId = 'ev1';
  const tNotes = [
    NoteEleve(
      studentId: 's1',
      firstName: 'Jean',
      lastName: 'Dupont',
      pointsObtenus: 15,
      statut: StatutNote.notee,
    ),
  ];

  setUp(() {
    mockRepository = MockNotationRepository();
    useCase = GetNotesElevesUseCase(mockRepository);
  });

  test('délègue au repository et renvoie Right(List<NoteEleve>)', () async {
    when(
      () => mockRepository.getNotesEleves(any()),
    ).thenAnswer((_) async => const Right(tNotes));

    final result = await useCase(tEvaluationId);

    expect(result, const Right<Failure, List<NoteEleve>>(tNotes));
    verify(() => mockRepository.getNotesEleves(tEvaluationId)).called(1);
  });

  test('propage le Left du repository', () async {
    when(
      () => mockRepository.getNotesEleves(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    final result = await useCase(tEvaluationId);

    expect(result, const Left<Failure, List<NoteEleve>>(NotFoundFailure()));
  });
}
