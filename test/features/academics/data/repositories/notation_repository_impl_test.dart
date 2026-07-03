import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/note_eleve_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/note_evaluation_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/saisir_note_request_model.dart';
import 'package:school_app_flutter/features/academics/data/repositories/notation_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

class MockCourseRemoteDataSource extends Mock
    implements CourseRemoteDataSource {}

void main() {
  late MockCourseRemoteDataSource mockDataSource;
  late NotationRepositoryImpl repository;
  const auth = <String, dynamic>{'requiresAuth': true};
  const tEvaluationId = 'ev1';

  setUpAll(() {
    registerFallbackValue(
      const SaisirNoteRequestModel(studentId: 's1', statut: StatutNote.notee),
    );
  });

  setUp(() {
    mockDataSource = MockCourseRemoteDataSource();
    repository = NotationRepositoryImpl(
      remoteDataSource: mockDataSource,
      requiredAuth: auth,
    );
  });

  group('getNotesEleves', () {
    const tModel = NoteEleveModel(
      studentId: 's1',
      firstName: 'Jean',
      lastName: 'Dupont',
      pointsObtenus: 15,
      statut: 'NOTEE',
    );

    test(
      'succès: mappe les modèles en entités + transmet requiredAuth',
      () async {
        when(
          () => mockDataSource.getNotesEleves(any(), any()),
        ).thenAnswer((_) async => const [tModel]);

        final result = await repository.getNotesEleves(tEvaluationId);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Right attendu'), (notes) {
          expect(notes, [tModel.toEntity()]);
          expect(notes.first.statut, StatutNote.notee);
        });
        verify(
          () => mockDataSource.getNotesEleves(auth, tEvaluationId),
        ).called(1);
      },
    );

    test('succès: liste vide -> Right([])', () async {
      when(
        () => mockDataSource.getNotesEleves(any(), any()),
      ).thenAnswer((_) async => <NoteEleveModel>[]);

      final result = await repository.getNotesEleves(tEvaluationId);

      result.fold((_) => fail('Right attendu'), (notes) {
        expect(notes, isEmpty);
      });
    });

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(() => mockDataSource.getNotesEleves(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const NotFoundFailure('Resource not found'),
        ),
      );

      final result = await repository.getNotesEleves(tEvaluationId);

      result.fold(
        (f) => expect(f, const NotFoundFailure('Resource not found')),
        (_) => fail('Left attendu'),
      );
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.getNotesEleves(any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.getNotesEleves(tEvaluationId);

      result.fold(
        (f) => expect(f, const NetworkFailure('Network error occurred')),
        (_) => fail('Left attendu'),
      );
    });

    test('Exception générique -> ServerFailure(erreur inattendue)', () async {
      when(
        () => mockDataSource.getNotesEleves(any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.getNotesEleves(tEvaluationId);

      result.fold(
        (f) => expect(f, const ServerFailure('Unexpected error occurred')),
        (_) => fail('Left attendu'),
      );
    });
  });

  group('saisirNote', () {
    final tRequest = SaisirNoteRequest.forStatut(
      studentId: 's1',
      statut: StatutNote.notee,
      pointsObtenus: 15,
    );
    const tResponseModel = NoteEvaluationModel(
      id: 'n1',
      evaluationId: tEvaluationId,
      studentId: 's1',
      pointsObtenus: 15,
      statut: 'NOTEE',
    );

    test('succès: mappe la réponse + transmet auth, evaluationId et le corps '
        'converti', () async {
      when(
        () => mockDataSource.saisirNote(any(), any(), any()),
      ).thenAnswer((_) async => tResponseModel);

      final result = await repository.saisirNote(tEvaluationId, tRequest);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Right attendu'), (note) {
        expect(note, tResponseModel.toEntity());
        expect(note.statut, StatutNote.notee);
        expect(note.pointsObtenus, 15.0);
      });

      final captured =
          verify(
                () => mockDataSource.saisirNote(
                  auth,
                  tEvaluationId,
                  captureAny(),
                ),
              ).captured.single
              as SaisirNoteRequestModel;
      final json = captured.toJson();
      expect(json['studentId'], 's1');
      expect(json['statut'], 'NOTEE');
      expect(json['pointsObtenus'], 15);
    });

    test(
      'corps ABSENT_JUSTIFIE : n\'émet pas pointsObtenus (règle 2)',
      () async {
        final absentRequest = SaisirNoteRequest.forStatut(
          studentId: 's1',
          statut: StatutNote.absentJustifie,
          pointsObtenus: 99, // ignoré côté domaine
        );
        const absentResponse = NoteEvaluationModel(
          id: 'n2',
          evaluationId: tEvaluationId,
          studentId: 's1',
          statut: 'ABSENT_JUSTIFIE',
        );
        when(
          () => mockDataSource.saisirNote(any(), any(), any()),
        ).thenAnswer((_) async => absentResponse);

        await repository.saisirNote(tEvaluationId, absentRequest);

        final captured =
            verify(
                  () => mockDataSource.saisirNote(
                    auth,
                    tEvaluationId,
                    captureAny(),
                  ),
                ).captured.single
                as SaisirNoteRequestModel;
        final json = captured.toJson();
        expect(json['statut'], 'ABSENT_JUSTIFIE');
        expect(json.containsKey('pointsObtenus'), isFalse);
      },
    );

    test(
      'DioException 400 (ValidationFailure) -> Left(ValidationFailure)',
      () async {
        when(() => mockDataSource.saisirNote(any(), any(), any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            error: const ValidationFailure('Invalid request data'),
          ),
        );

        final result = await repository.saisirNote(tEvaluationId, tRequest);

        result.fold(
          (f) => expect(f, const ValidationFailure('Invalid request data')),
          (_) => fail('Left attendu'),
        );
      },
    );

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.saisirNote(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.saisirNote(tEvaluationId, tRequest);

      result.fold(
        (f) => expect(f, const NetworkFailure('Network error occurred')),
        (_) => fail('Left attendu'),
      );
    });

    test('Exception générique -> ServerFailure(erreur inattendue)', () async {
      when(
        () => mockDataSource.saisirNote(any(), any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.saisirNote(tEvaluationId, tRequest);

      result.fold(
        (f) => expect(f, const ServerFailure('Unexpected error occurred')),
        (_) => fail('Left attendu'),
      );
    });
  });
}
