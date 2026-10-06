import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late AcademicsLocalDataSource academics;
  late EvaluationSujetLocalDataSource sujets;

  setUp(() async {
    db = await openFullOfflineDb();
    academics = AcademicsLocalDataSource(db);
    sujets = EvaluationSujetLocalDataSource(db);
  });
  tearDown(() => db.close());

  const row = EvaluationRow(
    id: 'ev-1',
    coursId: 'c-1',
    type: 'DEVOIR',
    evalDate: 500,
    maxPoints: 20,
    poids: 2,
    sousPeriodeId: 'sp-1',
    updatedAt: 1000,
    syncStatus: 'SYNCED',
    titre: 'Devoir 1',
  );

  const q1 = SujetQuestion(id: 'q-1', enonce: 'Équilibrez', points: 4);
  const q2 = SujetQuestion(id: 'q-2', enonce: 'Calculez', points: 3);

  Future<void> seed({EvaluationSujetRow? sujet}) =>
      academics.createEvaluationWithOutbox(
        row: row,
        sujet: sujet,
        outboxEntry: const OutboxEntry(
          id: 'ACADEMICS_EVALUATION:ev-1',
          aggregateType: 'ACADEMICS_EVALUATION',
          aggregateId: 'ev-1',
          operation: OutboxOperation.create,
          payload: '{}',
          createdAt: 1000,
        ),
      );

  /// Enregistre et rend (horloge retenue, maximum qui voyage).
  Future<(int?, double?)> save(
    EvaluationSujetRow sujet, {
    required int now,
    double? maxPoints,
    bool dropPendingMax = false,
  }) async {
    double? sentMax;
    final clock = await sujets.saveSujet(
      evaluationId: 'ev-1',
      sujet: sujet,
      now: now,
      maxPoints: maxPoints,
      dropPendingMax: dropPendingMax,
      buildOutboxEntry: (at, max) {
        sentMax = max;
        return OutboxEntry(
          id: 'ACADEMICS_EVALUATION_SUJET:ev-1',
          aggregateType: 'ACADEMICS_EVALUATION_SUJET',
          aggregateId: 'ev-1',
          operation: OutboxOperation.update,
          payload: '{}',
          createdAt: at,
        );
      },
    );
    return (clock, sentMax);
  }

  Future<EvaluationSujet> sujet() async =>
      (await sujets.getSujet('ev-1'))!.toEntity();

  test('la création écrit le cadre, statut d’envoi du sujet nul', () async {
    await seed(
      sujet: const EvaluationSujetRow(
        dureeMinutes: 60,
        programme: ['Réactions'],
        consignes: 'Calculatrice',
      ),
    );

    final read = (await sujets.getSujet('ev-1'))!;
    expect(read.dureeMinutes, 60);
    expect(read.syncStatus, isNull);
    expect((await academics.getEvaluation('ev-1'))!.titre, 'Devoir 1');
  });

  test('enregistre en attente et enfile, dans une transaction', () async {
    await seed();

    final (clock, sentMax) = await save(
      const EvaluationSujetRow(questions: [q1, q2]),
      now: 2000,
    );

    expect(clock, 2000);
    expect(sentMax, isNull, reason: 'maximum inchangé : il ne voyage pas');
    expect((await sujet()).questions, [q1, q2]);
    expect((await sujet()).envoi, SujetEnvoi.enAttente);
    expect(
      await OutboxDao(db).byId('ACADEMICS_EVALUATION_SUJET:ev-1'),
      isNotNull,
    );
  });

  test('évaluation absente : rien n’est écrit ni enfilé', () async {
    final (clock, _) = await save(const EvaluationSujetRow(), now: 2000);

    expect(clock, isNull);
    expect(await OutboxDao(db).byId('ACADEMICS_EVALUATION_SUJET:ev-1'), isNull);
  });

  test('horloge monotone : une horloge qui recule ne rajeunit pas', () async {
    await seed();
    await save(const EvaluationSujetRow(questions: [q1]), now: 5000);

    final (clock, _) = await save(
      const EvaluationSujetRow(questions: [q2]),
      now: 4000,
    );

    expect(clock, 5001);
  });

  group('maximum ajusté', () {
    test('porté par le sujet, il vaut sur la tablette et voyage jusqu’à '
        'l’accusé', () async {
      await seed();
      final (_, first) = await save(
        const EvaluationSujetRow(questions: [q1]),
        now: 2000,
        maxPoints: 4,
      );
      expect(first, 4);
      expect((await academics.getEvaluation('ev-1'))!.maxPoints, 4);

      // Un enregistrement suivant, sans ajustement, l'emporte encore.
      final (clock, second) = await save(
        const EvaluationSujetRow(questions: [q1, q2]),
        now: 3000,
      );
      expect(second, 4);

      // Le pull rafraîchit l'évaluation : l'ajustement en attente reste.
      await academics.applyPulledEvaluations([row]);
      expect((await academics.getEvaluation('ev-1'))!.maxPoints, 4);

      // Accusé : le maximum du serveur reprend la main.
      await sujets.markSujetSynced(
        evaluationId: 'ev-1',
        pushedUpdatedAt: clock!,
      );
      expect((await academics.getEvaluation('ev-1'))!.maxPoints, 20);
    });

    test('MAX_LOCKED : l’ajustement refusé est abandonné', () async {
      await seed();
      final (clock, _) = await save(
        const EvaluationSujetRow(questions: [q1]),
        now: 2000,
        maxPoints: 4,
      );

      await sujets.markSujetSyncError(
        evaluationId: 'ev-1',
        pushedUpdatedAt: clock!,
        rejectionCode: 'MAX_LOCKED',
        dropPendingMax: true,
      );

      expect((await sujet()).envoi, SujetEnvoi.refuse);
      expect((await academics.getEvaluation('ev-1'))!.maxPoints, 20);
      final (_, resent) = await save(
        const EvaluationSujetRow(questions: [q1]),
        now: 3000,
      );
      expect(resent, isNull);
    });
  });

  test('l’accusé est gardé par sujet_updated_at', () async {
    await seed();
    await save(const EvaluationSujetRow(), now: 3000);

    await sujets.markSujetSynced(evaluationId: 'ev-1', pushedUpdatedAt: 2000);
    expect((await sujet()).envoi, SujetEnvoi.enAttente);

    await sujets.markSujetSynced(evaluationId: 'ev-1', pushedUpdatedAt: 3000);
    expect((await sujet()).envoi, SujetEnvoi.envoye);
  });

  group('pull', () {
    EvaluationSujetRow server(List<SujetQuestion> qs, int at) =>
        EvaluationSujetRow(
          questions: qs,
          updatedAt: at,
          syncStatus: SyncState.synced.dbValue,
        );

    test('un brouillon en attente n’est jamais écrasé', () async {
      await seed();
      await save(const EvaluationSujetRow(questions: [q1]), now: 3000);

      final written = await sujets.applyPulledSujet(
        db,
        evaluationId: 'ev-1',
        sujet: server([q2], 9000),
      );

      expect(written, isFalse);
      expect((await sujet()).questions, [q1]);
    });

    test('un sujet accusé suit le serveur, jamais en arrière', () async {
      await seed();
      final (clock, _) = await save(
        const EvaluationSujetRow(questions: [q1]),
        now: 3000,
      );
      await sujets.markSujetSynced(
        evaluationId: 'ev-1',
        pushedUpdatedAt: clock!,
      );

      // Une page lue avant l'accusé : plus ancienne, ignorée.
      await sujets.applyPulledSujet(
        db,
        evaluationId: 'ev-1',
        sujet: server([q2], 2000),
      );
      expect((await sujet()).questions, [q1]);

      await sujets.applyPulledSujet(
        db,
        evaluationId: 'ev-1',
        sujet: server([q2], 4000),
      );
      expect((await sujet()).questions, [q2]);
    });

    test('rafraîchir l’évaluation ne touche pas son sujet', () async {
      await seed();
      await save(const EvaluationSujetRow(questions: [q1]), now: 3000);

      await academics.applyPulledEvaluations([
        const EvaluationRow(
          id: 'ev-1',
          coursId: 'c-1',
          type: 'DEVOIR',
          evalDate: 600,
          maxPoints: 20,
          poids: 2,
          sousPeriodeId: 'sp-1',
          updatedAt: 1000,
          syncStatus: 'SYNCED',
        ),
      ]);

      expect((await academics.getEvaluation('ev-1'))!.evalDate, 600);
      expect((await sujet()).questions, [q1]);
    });
  });
}
