import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_member_model.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/data/datasources/resultats_remote_data_source.dart';
import 'package:school_app_flutter/features/resultats/data/models/focus_entete_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultat_focus_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultats_classe_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultats_classe_stats_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/synthese_model.dart';
import 'package:school_app_flutter/features/resultats/data/repositories/resultats_repository_impl.dart';

class MockResultatsRemoteDataSource extends Mock
    implements ResultatsRemoteDataSource {}

const _auth = <String, dynamic>{'requiresAuth': true};

const _tClasseModel = ResultatsClasseModel(
  classroomId: 'class-1',
  periodeScolaireId: 'per-1',
  periodeOrdre: 1,
  sousPeriodes: [],
  stats: ResultatsClasseStatsModel(
    effectif: 1,
    seuil: 50.0,
    reussites: 0,
    echecs: 0,
    nonClasses: 0,
  ),
  lignes: [],
);

const _tFocusModel = ResultatFocusModel(
  classroomId: 'class-1',
  periodeScolaireId: 'per-1',
  periodeOrdre: 1,
  entete: FocusEnteteModel(
    studentId: 'stu-1',
    nom: 'Doe',
    prenom: 'Jane',
    nbClasses: 10,
  ),
  progression: [],
  topMatieres: [],
  bottomMatieres: [],
  synthese: SyntheseModel(nbClasses: 10),
);

const _tMemberModel = ClassroomMemberModel(
  id: 'm-1',
  studentId: 'stu-1',
  classroomId: 'class-1',
  academicYearId: 'ay-1',
  studentFirstName: 'Jane',
  studentLastName: 'Doe',
  studentGender: 'FEMALE',
);

void main() {
  late MockResultatsRemoteDataSource mockDataSource;
  late ResultatsRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockResultatsRemoteDataSource();
    repository = ResultatsRepositoryImpl(
      remoteDataSource: mockDataSource,
      requiredAuth: _auth,
    );
  });

  group('getResultatsClasse', () {
    test('succès: mappe le modèle + transmet auth et les 3 params', () async {
      when(
        () => mockDataSource.getResultatsClasse(any(), any(), any(), any()),
      ).thenAnswer((_) async => _tClasseModel);

      final result = await repository.getResultatsClasse(
        'class-1',
        'per-1',
        60,
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Right attendu'), (classe) {
        expect(classe, _tClasseModel.toEntity());
      });
      verify(
        () => mockDataSource.getResultatsClasse(_auth, 'class-1', 'per-1', 60),
      ).called(1);
    });

    test('seuil null transmis tel quel au data source', () async {
      when(
        () => mockDataSource.getResultatsClasse(any(), any(), any(), any()),
      ).thenAnswer((_) async => _tClasseModel);

      await repository.getResultatsClasse('class-1', 'per-1', null);

      verify(
        () =>
            mockDataSource.getResultatsClasse(_auth, 'class-1', 'per-1', null),
      ).called(1);
    });

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(
        () => mockDataSource.getResultatsClasse(any(), any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const NotFoundFailure(),
        ),
      );

      final result = await repository.getResultatsClasse('c', 'p', null);

      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.getResultatsClasse(any(), any(), any(), any()),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.getResultatsClasse('c', 'p', null);

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('Exception générique -> ServerFailure', () async {
      when(
        () => mockDataSource.getResultatsClasse(any(), any(), any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.getResultatsClasse('c', 'p', null);

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });

  group('getResultatFocus', () {
    test(
      'succès: mappe le modèle + ordre des params (studentId d\'abord)',
      () async {
        when(
          () => mockDataSource.getResultatFocus(any(), any(), any(), any()),
        ).thenAnswer((_) async => _tFocusModel);

        final result = await repository.getResultatFocus(
          'class-1',
          'per-1',
          'stu-1',
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Right attendu'), (focus) {
          expect(focus, _tFocusModel.toEntity());
        });
        // Le repository réordonne : (auth, studentId, classroomId, periode).
        verify(
          () => mockDataSource.getResultatFocus(
            _auth,
            'stu-1',
            'class-1',
            'per-1',
          ),
        ).called(1);
      },
    );

    test('DioException portant une Failure -> Left(cette Failure)', () async {
      when(
        () => mockDataSource.getResultatFocus(any(), any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          error: const UnauthorizedFailure(),
        ),
      );

      final result = await repository.getResultatFocus('c', 'p', 's');

      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('Left attendu'),
      );
    });

    test('Exception générique -> ServerFailure', () async {
      when(
        () => mockDataSource.getResultatFocus(any(), any(), any(), any()),
      ).thenThrow(Exception('boom'));

      final result = await repository.getResultatFocus('c', 'p', 's');

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });

  group('searchRoster', () {
    test(
      'succès: mappe la liste de modèles en entités + transmet les params',
      () async {
        when(
          () => mockDataSource.searchRoster(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        ).thenAnswer((_) async => [_tMemberModel]);

        final result = await repository.searchRoster(
          'class-1',
          'ay-1',
          'Doe',
          null,
          null,
        );

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Right attendu'), (eleves) {
          expect(eleves, isA<List<ClassroomMember>>());
          expect(eleves, [_tMemberModel.toEntity()]);
          expect(eleves.single.studentGender, ClassroomMemberGender.female);
        });
        verify(
          () => mockDataSource.searchRoster(
            _auth,
            'class-1',
            'ay-1',
            'Doe',
            null,
            null,
          ),
        ).called(1);
      },
    );

    test('succès: liste vide -> Right([])', () async {
      when(
        () => mockDataSource.searchRoster(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => <ClassroomMemberModel>[]);

      final result = await repository.searchRoster('c', 'ay', null, null, null);

      result.fold((_) => fail('Right attendu'), (eleves) {
        expect(eleves, isEmpty);
      });
    });

    test('DioException sans Failure -> NetworkFailure', () async {
      when(
        () => mockDataSource.searchRoster(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/x')));

      final result = await repository.searchRoster('c', 'ay', null, null, null);

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Left attendu'),
      );
    });
  });
}
