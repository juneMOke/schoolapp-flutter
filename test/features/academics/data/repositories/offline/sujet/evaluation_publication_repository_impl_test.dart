import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sujet_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_publication_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_publication_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';

import '../../../../../../core/offline/offline_full_test_db.dart';

class _MockApi extends Mock implements AcademicsEvaluationSujetApi {}

void main() {
  late Database db;
  late _MockApi api;
  late EvaluationPublicationRepositoryImpl repo;
  late AcademicsLocalDataSource academics;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    academics = AcademicsLocalDataSource(db);
    repo = EvaluationPublicationRepositoryImpl(
      api: api,
      publications: EvaluationPublicationLocalDataSource(db),
      academics: academics,
      sujets: EvaluationSujetLocalDataSource(db),
      requiredAuth: auth,
    );
    await academics.applyPulledEvaluations(const [
      EvaluationRow(
        id: 'ev-1',
        coursId: 'c-1',
        type: 'DEVOIR',
        evalDate: 0,
        maxPoints: 20,
        poids: 2,
        sousPeriodeId: 'sp-1',
        updatedAt: 0,
        syncStatus: 'SYNCED',
      ),
    ]);
  });
  tearDown(() => db.close());

  DioException refused(String code, {Map<String, dynamic>? details}) =>
      DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 422,
          data: {'detailCode': code, 'details': ?details},
        ),
      );

  test('contexte : des notes en file retiennent la publication', () async {
    final ctx = (await repo.getContext(
      'ev-1',
    )).getOrElse(() => const PublicationContext());
    expect(ctx.anythingPending, isFalse);

    await academics.upsertNotesWithOutbox(
      incoming: const [
        NoteEvaluationRow(
          id: 'n-1',
          evaluationId: 'ev-1',
          studentId: 's-1',
          pointsObtenus: 12,
          statut: 'NOTEE',
          updatedAt: 10,
        ),
      ],
      evaluationId: 'ev-1',
      buildOutboxEntry: (_) => const OutboxEntry(
        id: 'ACADEMICS_NOTES_BATCH:ev-1',
        aggregateType: 'ACADEMICS_NOTES_BATCH',
        aggregateId: 'ev-1',
        operation: OutboxOperation.upsert,
        payload: '{}',
        createdAt: 10,
      ),
    );
    final after = (await repo.getContext(
      'ev-1',
    )).getOrElse(() => const PublicationContext());
    expect(after.notesPending, isTrue);
  });

  test('publier écrit l’état rendu par le serveur', () async {
    when(() => api.publish(auth, 'ev-1', 'corrige')).thenAnswer(
      (_) async => PublicationStateModel.fromJson({
        'publishedAt': '2026-10-06T11:00:00Z',
        'revision': 2,
      }),
    );

    final result = await repo.publish('ev-1', PublicationKind.corrige);

    expect(result.getOrElse(() => throw StateError('')).revision, 2);
    final local = await EvaluationPublicationLocalDataSource(
      db,
    ).getPublications('ev-1');
    expect(local.corrige!.revision, 2);
  });

  test('EVALUATION_INCOMPLETE : refus typé avec les chiffres', () async {
    when(() => api.publish(auth, 'ev-1', 'notes')).thenThrow(
      refused(
        'EVALUATION_INCOMPLETE',
        details: {'saisies': 18, 'effectif': 28},
      ),
    );

    final result = await repo.publish('ev-1', PublicationKind.notes);

    expect(
      result.fold((f) => f, (_) => null),
      const PublicationRefusedFailure(
        'EVALUATION_INCOMPLETE',
        saisies: 18,
        effectif: 28,
      ),
    );
  });

  test('retirer remet « non publié »', () async {
    await EvaluationPublicationLocalDataSource(db).setPublication(
      'ev-1',
      PublicationKind.sujet,
      PublicationEtat(publishedAt: DateTime.utc(2026, 10, 6)),
    );
    when(() => api.withdraw(auth, 'ev-1', 'sujet')).thenAnswer((_) async {});

    await repo.withdraw('ev-1', PublicationKind.sujet);

    expect(
      (await EvaluationPublicationLocalDataSource(
        db,
      ).getPublications('ev-1')).sujet,
      isNull,
    );
  });

  test('hors ligne : NetworkFailure, rien n’est écrit', () async {
    when(() => api.publish(auth, 'ev-1', 'sujet')).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
        error: const NetworkFailure(),
      ),
    );

    final result = await repo.publish('ev-1', PublicationKind.sujet);

    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    expect(
      (await EvaluationPublicationLocalDataSource(
        db,
      ).getPublications('ev-1')).sujet,
      isNull,
    );
  });
}
