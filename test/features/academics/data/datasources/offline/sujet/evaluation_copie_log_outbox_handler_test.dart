import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sujet_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_copie_log_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_child_outbox_support.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_copie_log_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_view_applier.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_copie_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';

import '../../../../../../core/offline/offline_full_test_db.dart';

class _MockApi extends Mock implements AcademicsEvaluationSujetApi {}

class _MockIds extends Mock implements IdGenerator {}

void main() {
  late Database db;
  late _MockApi api;
  late EvaluationCopieRepositoryImpl repo;
  late EvaluationCopieLogLocalDataSource local;
  late EvaluationCopieLogOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    local = EvaluationCopieLogLocalDataSource(db);
    final ids = _MockIds();
    when(ids.newId).thenReturn('l-1');
    final user = CurrentUserContext()..set('teacher');
    repo = EvaluationCopieRepositoryImpl(
      localDataSource: local,
      idGenerator: ids,
      currentUser: user,
      now: () => 1000,
    );
    handler = EvaluationCopieLogOutboxHandler(
      api: api,
      copieLog: local,
      views: EvaluationViewApplier.on(db),
      support: EvaluationChildOutboxSupport(
        academics: AcademicsLocalDataSource(db),
        currentUser: user,
      ),
      requiredAuth: auth,
    );
    await AcademicsLocalDataSource(db).applyPulledEvaluations(const [
      EvaluationRow(
        id: 'ev-1',
        coursId: 'c-1',
        type: 'INTERRO',
        evalDate: 0,
        maxPoints: 10,
        poids: 1,
        sousPeriodeId: 'sp-1',
        updatedAt: 0,
        syncStatus: 'SYNCED',
      ),
    ]);
  });
  tearDown(() => db.close());

  Future<OutboxDispatchResult> dispatch() async {
    final entry = await OutboxDao(
      db,
    ).byId('$kEvaluationCopieLogAggregateType:l-1');
    return handler.dispatch(entry!);
  }

  test('un partage journalisé part par le canal du système', () async {
    final logged = await repo.logDiffusion(
      'ev-1',
      kind: CopieKind.share,
      corrige: true,
    );
    expect(logged.isRight(), isTrue);
    when(() => api.logCopie(auth, 'ev-1', any())).thenAnswer(
      (_) async => EvaluationDeltaDto.fromJson({
        'id': 'ev-1',
        'coursId': 'c-1',
        'type': 'INTERRO',
        'date': '2026-10-14',
        'maxPoints': 10,
        'serverUpdatedAt': '2026-10-06T09:00:00Z',
      }),
    );

    expect((await dispatch()).outcome, OutboxDispatchOutcome.acked);
    final body =
        verify(() => api.logCopie(auth, 'ev-1', captureAny())).captured.single
            as Map<String, dynamic>;
    expect((body['entry'] as Map)['canal'], 'SYSTEME');
    expect(
      (await local.getForEvaluation('ev-1')).single.syncState,
      SyncState.synced,
    );
  });

  test('une impression ne porte pas de canal', () async {
    await repo.logDiffusion('ev-1', kind: CopieKind.print, corrige: false);
    expect((await local.getForEvaluation('ev-1')).single.canal, isNull);
  });

  test('COPIE_LOG_MISMATCH : terminal', () async {
    await repo.logDiffusion('ev-1', kind: CopieKind.print, corrige: false);
    when(() => api.logCopie(auth, 'ev-1', any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 422,
          data: {'detailCode': 'COPIE_LOG_MISMATCH'},
        ),
      ),
    );

    expect((await dispatch()).outcome, OutboxDispatchOutcome.failed);
    expect(
      (await local.getForEvaluation('ev-1')).single.syncState,
      SyncState.syncError,
    );
  });
}
