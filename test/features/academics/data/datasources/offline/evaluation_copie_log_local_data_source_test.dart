import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_copie_log_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/copie_log_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late EvaluationCopieLogLocalDataSource journal;

  setUp(() async {
    db = await openFullOfflineDb();
    journal = EvaluationCopieLogLocalDataSource(db);
  });
  tearDown(() => db.close());

  CopieLogRow log(String id, {int at = 1000, String kind = 'PRINT'}) =>
      CopieLogRow(
        id: id,
        evaluationId: 'ev-1',
        kind: kind,
        canal: kind == 'SHARE' ? 'SYSTEME' : null,
        corrige: false,
        occurredAt: at,
      );

  test('insertion + entrée d’outbox, rejeu sans doublon', () async {
    const entry = OutboxEntry(
      id: 'ACADEMICS_COPIE_LOG:l-1',
      aggregateType: 'ACADEMICS_COPIE_LOG',
      aggregateId: 'l-1',
      operation: OutboxOperation.create,
      payload: '{}',
      createdAt: 1000,
    );

    await journal.insertWithOutbox(log('l-1'), outboxEntry: entry);
    await journal.insertWithOutbox(log('l-1'), outboxEntry: entry);

    expect(await journal.getForEvaluation('ev-1'), hasLength(1));
    expect(await OutboxDao(db).byId('ACADEMICS_COPIE_LOG:l-1'), isNotNull);
  });

  test('journal le plus récent d’abord', () async {
    await journal.insertWithOutbox(log('l-1', at: 1000));
    await journal.insertWithOutbox(log('l-2', at: 3000, kind: 'SHARE'));

    final rows = await journal.getForEvaluation('ev-1');
    expect(rows.map((r) => r.id), ['l-2', 'l-1']);
    expect(rows.first.toEntity()!.canal, CopieCanal.systeme);
  });

  test('le pull ajoute les lignes inconnues et accuse les locales', () async {
    await journal.insertWithOutbox(log('l-1'));

    await journal.applyPulled(db, [log('l-1'), log('l-9', at: 5000)]);

    final rows = await journal.getForEvaluation('ev-1');
    expect(rows.map((r) => r.id), ['l-9', 'l-1']);
    expect(rows.every((r) => r.syncState == SyncState.synced), isTrue);
  });

  test('l’éviction d’un cours emporte son journal', () async {
    final academics = AcademicsLocalDataSource(db);
    await academics.applyPulledEvaluations(const [
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
    await journal.insertWithOutbox(log('l-1'));

    await academics.evictCoursData('c-1');

    expect(await journal.getForEvaluation('ev-1'), isEmpty);
  });
}
