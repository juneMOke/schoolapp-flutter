import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/notation_repository.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/saisir_note_usecase.dart';

class MockNotationRepository extends Mock implements NotationRepository {}

void main() {
  late MockNotationRepository mockRepository;
  late SaisirNoteUseCase useCase;

  const tEvaluationId = 'ev1';
  final tRequest = SaisirNoteRequest.forStatut(
    studentId: 's1',
    statut: StatutNote.notee,
    pointsObtenus: 15,
  );
  const tNoteEvaluation = NoteEvaluation(
    id: 'n1',
    evaluationId: tEvaluationId,
    studentId: 's1',
    pointsObtenus: 15,
    statut: StatutNote.notee,
  );

  setUpAll(() {
    registerFallbackValue(
      SaisirNoteRequest.forStatut(
        studentId: 's1',
        statut: StatutNote.enAttente,
      ),
    );
  });

  setUp(() {
    mockRepository = MockNotationRepository();
    useCase = SaisirNoteUseCase(mockRepository);
  });

  test('délègue au repository et renvoie Right(NoteEvaluation)', () async {
    when(
      () => mockRepository.saisirNote(any(), any()),
    ).thenAnswer((_) async => const Right(tNoteEvaluation));

    final result = await useCase(tEvaluationId, tRequest);

    expect(result, const Right<Failure, NoteEvaluation>(tNoteEvaluation));
    verify(() => mockRepository.saisirNote(tEvaluationId, tRequest)).called(1);
  });

  test('propage le Left du repository', () async {
    when(
      () => mockRepository.saisirNote(any(), any()),
    ).thenAnswer((_) async => const Left(ValidationFailure()));

    final result = await useCase(tEvaluationId, tRequest);

    expect(result, const Left<Failure, NoteEvaluation>(ValidationFailure()));
  });
}
