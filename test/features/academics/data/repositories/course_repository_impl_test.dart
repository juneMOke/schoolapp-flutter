import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/course_remote_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/classroom_summary_model.dart';
import 'package:school_app_flutter/features/academics/data/models/course_ref_model.dart';
import 'package:school_app_flutter/features/academics/data/models/course_summary_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/cours_notation_detail_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/create_evaluation_request_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/evaluation_model.dart';
import 'package:school_app_flutter/features/academics/data/repositories/course_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';

class MockCourseRemoteDataSource extends Mock
    implements CourseRemoteDataSource {}

void main() {
  late MockCourseRemoteDataSource mockDataSource;
  late CourseRepositoryImpl repository;
  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(
      CreateEvaluationRequestModel(
        type: 'EXAMEN',
        date: DateTime(2025),
        maxPoints: 1,
      ),
    );
  });

  const tModel = CourseSummaryModel(
    classroom: ClassroomSummaryModel(
      id: 'c1',
      version: 3,
      schoolLevelId: 'lvl-1',
      name: '6ème A',
      capacity: 40,
      totalCount: 32,
      femaleCount: 18,
      maleCount: 14,
    ),
    courses: [
      CourseRefModel(id: 'crs-1', label: 'Algèbre'),
      CourseRefModel(id: 'crs-2', label: 'Français'),
    ],
  );

  const tCoursId = 'cours-1';
  const tNotationModel = CoursNotationDetailModel(
    coursId: tCoursId,
    classroomId: 'class-1',
    brancheNom: 'Mathématiques',
    effectif: 30,
    periodes: [],
  );

  setUp(() {
    mockDataSource = MockCourseRemoteDataSource();
    repository = CourseRepositoryImpl(
      remoteDataSource: mockDataSource,
      requiredAuth: auth,
    );
  });

  test(
    'succès: mappe les modèles en entités + transmet requiredAuth',
    () async {
      when(
        () => mockDataSource.getMyCourses(any()),
      ).thenAnswer((_) async => [tModel]);

      final result = await repository.getMyCourses();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Right attendu'), (courses) {
        expect(courses, [tModel.toEntity()]);
        expect(courses.first.classroom.name, '6ème A');
        expect(courses.first.courses, const [
          CourseRef(id: 'crs-1', label: 'Algèbre'),
          CourseRef(id: 'crs-2', label: 'Français'),
        ]);
      });
      verify(() => mockDataSource.getMyCourses(auth)).called(1);
    },
  );

  test('succès: liste vide -> Right([])', () async {
    when(
      () => mockDataSource.getMyCourses(any()),
    ).thenAnswer((_) async => <CourseSummaryModel>[]);

    final result = await repository.getMyCourses();

    result.fold((_) => fail('Right attendu'), (courses) {
      expect(courses, isEmpty);
    });
  });

  test('DioException portant une Failure -> Left(cette Failure)', () async {
    when(() => mockDataSource.getMyCourses(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const NotFoundFailure('Resource not found'),
      ),
    );

    final result = await repository.getMyCourses();

    result.fold((f) {
      expect(f, isA<NotFoundFailure>());
      expect(f, const NotFoundFailure('Resource not found'));
    }, (_) => fail('Left attendu'));
  });

  test('DioException sans Failure -> NetworkFailure', () async {
    when(
      () => mockDataSource.getMyCourses(any()),
    ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

    final result = await repository.getMyCourses();

    result.fold((f) {
      expect(f, isA<NetworkFailure>());
      expect(f, const NetworkFailure('Network error occurred'));
    }, (_) => fail('Left attendu'));
  });

  test('Exception générique -> ServerFailure(erreur inattendue)', () async {
    when(() => mockDataSource.getMyCourses(any())).thenThrow(Exception('boom'));

    final result = await repository.getMyCourses();

    result.fold((f) {
      expect(f, isA<ServerFailure>());
      expect(f, const ServerFailure('Unexpected error occurred'));
    }, (_) => fail('Left attendu'));
  });

  group('getCoursNotationDetail', () {
    test('succès: mappe le modèle en entité + transmet requiredAuth', () async {
      when(
        () => mockDataSource.getCoursNotationDetail(any(), any()),
      ).thenAnswer((_) async => tNotationModel);

      final result = await repository.getCoursNotationDetail(tCoursId);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Right attendu'), (detail) {
        expect(detail, tNotationModel.toEntity());
        expect(detail.coursId, tCoursId);
        expect(detail.brancheNom, 'Mathématiques');
        expect(detail.effectif, 30);
      });
      verify(
        () => mockDataSource.getCoursNotationDetail(auth, tCoursId),
      ).called(1);
    });

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(() => mockDataSource.getCoursNotationDetail(any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const NotFoundFailure('Resource not found'),
        ),
      );

      final result = await repository.getCoursNotationDetail(tCoursId);

      result.fold((f) {
        expect(f, isA<NotFoundFailure>());
        expect(f, const NotFoundFailure('Resource not found'));
      }, (_) => fail('Left attendu'));
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.getCoursNotationDetail(any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.getCoursNotationDetail(tCoursId);

      result.fold((f) {
        expect(f, isA<NetworkFailure>());
        expect(f, const NetworkFailure('Network error occurred'));
      }, (_) => fail('Left attendu'));
    });

    test('Exception générique -> ServerFailure(erreur inattendue)', () async {
      when(
        () => mockDataSource.getCoursNotationDetail(any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.getCoursNotationDetail(tCoursId);

      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f, const ServerFailure('Unexpected error occurred'));
      }, (_) => fail('Left attendu'));
    });
  });

  group('createEvaluation', () {
    final tDate = DateTime(2025, 11, 10);
    final tRequest = CreateEvaluationRequest.examen(
      date: tDate,
      maxPoints: 20,
      periodeScolaireId: 'periode-1',
    );
    final tEvaluationModel = EvaluationModel(
      id: 'ev-1',
      coursId: tCoursId,
      type: 'EXAMEN',
      date: tDate,
      maxPoints: 20,
      poids: 1,
      periodeScolaireId: 'periode-1',
    );

    test(
      'succès: mappe le modèle en entité + transmet auth, coursId et le corps '
      'converti',
      () async {
        when(
          () => mockDataSource.createEvaluation(any(), any(), any()),
        ).thenAnswer((_) async => tEvaluationModel);

        final result = await repository.createEvaluation(tCoursId, tRequest);

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Right attendu'), (evaluation) {
          expect(evaluation, tEvaluationModel.toEntity());
          expect(evaluation.id, 'ev-1');
          expect(evaluation.type, TypeEvaluation.examen);
          expect(evaluation.periodeScolaireId, 'periode-1');
        });

        final captured =
            verify(
                  () => mockDataSource.createEvaluation(
                    auth,
                    tCoursId,
                    captureAny(),
                  ),
                ).captured.single
                as CreateEvaluationRequestModel;
        final json = captured.toJson();
        expect(json['type'], 'EXAMEN');
        expect(json['periodeScolaireId'], 'periode-1');
        expect(json.containsKey('sousPeriodeId'), isFalse);
        expect(json.containsKey('poids'), isFalse);
      },
    );

    test('chemin journalière (INTERRO) : corps converti porte sousPeriodeId et '
        'poids, sans periodeScolaireId', () async {
      final interroRequest = CreateEvaluationRequest.journaliere(
        type: TypeEvaluation.interro,
        date: tDate,
        maxPoints: 10,
        sousPeriodeId: 'sous-periode-1',
        poids: 2,
      );
      final interroModel = EvaluationModel(
        id: 'ev-2',
        coursId: tCoursId,
        type: 'INTERRO',
        date: tDate,
        maxPoints: 10,
        poids: 2,
        sousPeriodeId: 'sous-periode-1',
      );
      when(
        () => mockDataSource.createEvaluation(any(), any(), any()),
      ).thenAnswer((_) async => interroModel);

      final result = await repository.createEvaluation(
        tCoursId,
        interroRequest,
      );

      result.fold((_) => fail('Right attendu'), (evaluation) {
        expect(evaluation.type, TypeEvaluation.interro);
        expect(evaluation.sousPeriodeId, 'sous-periode-1');
        expect(evaluation.periodeScolaireId, isNull);
      });

      final captured =
          verify(
                () => mockDataSource.createEvaluation(
                  auth,
                  tCoursId,
                  captureAny(),
                ),
              ).captured.single
              as CreateEvaluationRequestModel;
      final json = captured.toJson();
      expect(json['type'], 'INTERRO');
      expect(json['sousPeriodeId'], 'sous-periode-1');
      expect(json['poids'], 2);
      expect(json.containsKey('periodeScolaireId'), isFalse);
    });

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(
        () => mockDataSource.createEvaluation(any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const ValidationFailure('Invalid request data'),
        ),
      );

      final result = await repository.createEvaluation(tCoursId, tRequest);

      result.fold((f) {
        expect(f, isA<ValidationFailure>());
        expect(f, const ValidationFailure('Invalid request data'));
      }, (_) => fail('Left attendu'));
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.createEvaluation(any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.createEvaluation(tCoursId, tRequest);

      result.fold((f) {
        expect(f, isA<NetworkFailure>());
        expect(f, const NetworkFailure('Network error occurred'));
      }, (_) => fail('Left attendu'));
    });

    test('Exception générique -> ServerFailure(erreur inattendue)', () async {
      when(
        () => mockDataSource.createEvaluation(any(), any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.createEvaluation(tCoursId, tRequest);

      result.fold((f) {
        expect(f, isA<ServerFailure>());
        expect(f, const ServerFailure('Unexpected error occurred'));
      }, (_) => fail('Left attendu'));
    });
  });
}
