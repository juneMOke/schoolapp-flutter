import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sujet_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_child_outbox_support.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_sujet_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_view_applier.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_sujet_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

import '../../../../../../core/offline/offline_full_test_db.dart';

class _MockApi extends Mock implements AcademicsEvaluationSujetApi {}

void main() {
  late Database db;
  late _MockApi api;
  late EvaluationSujetRepositoryImpl repo;
  late EvaluationSujetLocalDataSource sujets;
  late EvaluationSujetOutboxHandler handler;
  late OutboxDao outbox;

  const auth = <String, dynamic>{'requiresAuth': true};
  const savedAt = 1759737600000; // 2025-10-06T08:00:00Z
  const q = SujetQuestion(id: 'q1', enonce: 'Q', points: 10);

  Future<void> seedEvaluation(String status) =>
      AcademicsLocalDataSource(db).createEvaluationWithOutbox(
        row: EvaluationRow(
          id: 'ev-1',
          coursId: 'c-1',
          type: 'INTERRO',
          evalDate: 0,
          maxPoints: 10,
          poids: 1,
          sousPeriodeId: 'sp-1',
          updatedAt: 0,
          syncStatus: status,
        ),
        outboxEntry: const OutboxEntry(
          id: 'ACADEMICS_EVALUATION:ev-1',
          aggregateType: 'ACADEMICS_EVALUATION',
          aggregateId: 'ev-1',
          operation: OutboxOperation.create,
          payload: '{}',
          createdAt: 0,
        ),
      );

  EvaluationDeltaDto view({String? sujetAt, List<Map<String, dynamic>>? qs}) =>
      EvaluationDeltaDto.fromJson({
        'id': 'ev-1',
        'coursId': 'c-1',
        'type': 'INTERRO',
        'date': '2025-10-14',
        'maxPoints': 10,
        'poids': 1,
        'sousPeriodeId': 'sp-1',
        'serverUpdatedAt': '2025-10-06T09:00:00Z',
        'sujetClientUpdatedAt': sujetAt,
        'questions':
            qs ??
            [
              {'id': 'q1', 'ordre': 1, 'enonce': 'Q', 'points': 10},
            ],
      });

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    sujets = EvaluationSujetLocalDataSource(db);
    outbox = OutboxDao(db);
    final user = CurrentUserContext()..set('teacher');
    repo = EvaluationSujetRepositoryImpl(
      localDataSource: sujets,
      currentUser: user,
      now: () => savedAt,
    );
    handler = EvaluationSujetOutboxHandler(
      api: api,
      sujets: sujets,
      views: EvaluationViewApplier.on(db),
      support: EvaluationChildOutboxSupport(
        academics: AcademicsLocalDataSource(db),
        currentUser: user,
      ),
      requiredAuth: auth,
      now: () => savedAt + 1,
    );
  });
  tearDown(() => db.close());

  Future<OutboxDispatchResult> saveAndDispatch() async {
    await repo.saveSujet(
      'ev-1',
      cadre: const EvaluationCadre(),
      questions: const [q],
    );
    final entry = await outbox.byId(
      EvaluationSujetRepositoryImpl.outboxId('ev-1'),
    );
    return handler.dispatch(entry!);
  }

  Future<EvaluationSujet> localSujet() async =>
      (await sujets.getSujet('ev-1'))!.toEntity();

  test('évaluation pas encore accusée : l’envoi attend', () async {
    await seedEvaluation('PENDING_SYNC');
    final result = await saveAndDispatch();
    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.replaceSujet(any(), any(), any()));
  });

  test(
    'accepté : le sujet passe envoyé ; un maximum inchangé ne part pas',
    () async {
      await seedEvaluation('SYNCED');
      when(
        () => api.replaceSujet(auth, 'ev-1', any()),
      ).thenAnswer((_) async => view(sujetAt: '2025-10-06T08:00:00.000Z'));

      final result = await saveAndDispatch();

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect((await localSujet()).envoi, SujetEnvoi.envoye);
      final body =
          verify(
                () => api.replaceSujet(auth, 'ev-1', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(body.containsKey('maxPoints'), isFalse);
      expect(body['authorId'], 'teacher');
    },
  );

  test('le serveur gardait plus récent : on prend le sien', () async {
    await seedEvaluation('SYNCED');
    when(() => api.replaceSujet(auth, 'ev-1', any())).thenAnswer(
      (_) async => view(
        sujetAt: '2025-10-06T09:30:00.000Z',
        qs: [
          {'id': 'q9', 'ordre': 1, 'enonce': 'Autre', 'points': 10},
        ],
      ),
    );

    await saveAndDispatch();

    final sujet = await localSujet();
    expect(sujet.questions.single.id, 'q9');
    expect(sujet.envoi, SujetEnvoi.envoye);
  });

  test('MAX_LOCKED : refus terminal, brouillon gardé avec son code', () async {
    await seedEvaluation('SYNCED');
    when(() => api.replaceSujet(auth, 'ev-1', any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 422,
          data: {'detailCode': 'MAX_LOCKED'},
        ),
      ),
    );

    final result = await saveAndDispatch();

    expect(result.outcome, OutboxDispatchOutcome.failed);
    final sujet = await localSujet();
    expect(sujet.envoi, SujetEnvoi.refuse);
    expect(sujet.rejectionCode, 'MAX_LOCKED');
    expect(sujet.questions, [q]);
  });

  test('400 : refus terminal, le brouillon est marqué refusé', () async {
    await seedEvaluation('SYNCED');
    when(() => api.replaceSujet(auth, 'ev-1', any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 400),
        error: const ValidationFailure(),
      ),
    );

    expect((await saveAndDispatch()).outcome, OutboxDispatchOutcome.failed);
    final sujet = await localSujet();
    expect(sujet.envoi, SujetEnvoi.refuse);
    expect(sujet.rejectionCode, 'REJECTED');
  });

  test('404 (évaluation pas encore acquittée) : nouvel essai', () async {
    await seedEvaluation('SYNCED');
    when(() => api.replaceSujet(auth, 'ev-1', any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      ),
    );
    expect((await saveAndDispatch()).outcome, OutboxDispatchOutcome.retry);
  });

  test('renvoi sans maximum : un ajustement en attente ne part plus', () async {
    await seedEvaluation('SYNCED');
    await repo.saveSujet(
      'ev-1',
      cadre: const EvaluationCadre(),
      questions: const [q],
      maxPoints: 10,
    );
    await repo.resendSujetWithoutMax('ev-1');
    when(
      () => api.replaceSujet(auth, 'ev-1', any()),
    ).thenAnswer((_) async => view(sujetAt: '2025-10-06T08:00:00.000Z'));

    final entry = await outbox.byId(
      EvaluationSujetRepositoryImpl.outboxId('ev-1'),
    );
    await handler.dispatch(entry!);

    final body =
        verify(
              () => api.replaceSujet(auth, 'ev-1', captureAny()),
            ).captured.single
            as Map<String, dynamic>;
    expect(body.containsKey('maxPoints'), isFalse);
  });
}
