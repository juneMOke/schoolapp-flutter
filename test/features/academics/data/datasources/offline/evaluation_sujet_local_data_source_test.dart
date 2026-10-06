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

  OutboxEntry entry() => const OutboxEntry(
    id: 'ACADEMICS_EVALUATION_SUJET:ev-1',
    aggregateType: 'ACADEMICS_EVALUATION_SUJET',
    aggregateId: 'ev-1',
    operation: OutboxOperation.update,
    payload: '{}',
    createdAt: 2000,
  );

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

  test('la création écrit le cadre, statut d’envoi du sujet nul', () async {
    await seed(
      sujet: const EvaluationSujetRow(
        dureeMinutes: 60,
        programme: ['Réactions'],
        consignes: 'Calculatrice',
      ),
    );

    final sujet = (await sujets.getSujet('ev-1'))!;
    expect(sujet.dureeMinutes, 60);
    expect(sujet.programme, ['Réactions']);
    expect(sujet.syncStatus, isNull);
    expect(sujet.toEntity().envoi, SujetEnvoi.initial);
    expect((await academics.getEvaluation('ev-1'))!.titre, 'Devoir 1');
  });

  test('saveSujet écrit sujet + max + outbox dans une transaction', () async {
    await seed();

    final saved = await sujets.saveSujet(
      evaluationId: 'ev-1',
      sujet: const EvaluationSujetRow(questions: [q1, q2], updatedAt: 2000),
      maxPoints: 7,
      outboxEntry: entry(),
    );

    expect(saved, isTrue);
    final sujet = (await sujets.getSujet('ev-1'))!;
    expect(sujet.questions, [q1, q2]);
    expect(sujet.toEntity().envoi, SujetEnvoi.enAttente);
    expect((await academics.getEvaluation('ev-1'))!.maxPoints, 7);
    expect(
      await OutboxDao(db).byId('ACADEMICS_EVALUATION_SUJET:ev-1'),
      isNotNull,
    );
  });

  test('saveSujet sur une évaluation absente n’enfile rien', () async {
    final saved = await sujets.saveSujet(
      evaluationId: 'absente',
      sujet: const EvaluationSujetRow(updatedAt: 2000),
      outboxEntry: entry(),
    );

    expect(saved, isFalse);
    expect(await OutboxDao(db).byId('ACADEMICS_EVALUATION_SUJET:ev-1'), isNull);
  });

  test('l’accusé est gardé par sujet_updated_at', () async {
    await seed();
    await sujets.saveSujet(
      evaluationId: 'ev-1',
      sujet: const EvaluationSujetRow(updatedAt: 3000),
    );

    await sujets.markSujetSynced(evaluationId: 'ev-1', pushedUpdatedAt: 2000);
    expect(
      (await sujets.getSujet('ev-1'))!.toEntity().envoi,
      SujetEnvoi.enAttente,
    );

    await sujets.markSujetSynced(evaluationId: 'ev-1', pushedUpdatedAt: 3000);
    expect(
      (await sujets.getSujet('ev-1'))!.toEntity().envoi,
      SujetEnvoi.envoye,
    );
  });

  test('un refus garde le brouillon et porte son code', () async {
    await seed();
    await sujets.saveSujet(
      evaluationId: 'ev-1',
      sujet: const EvaluationSujetRow(questions: [q1], updatedAt: 3000),
    );

    await sujets.markSujetSyncError(
      evaluationId: 'ev-1',
      pushedUpdatedAt: 3000,
      rejectionCode: 'MAX_LOCKED',
    );

    final sujet = (await sujets.getSujet('ev-1'))!.toEntity();
    expect(sujet.envoi, SujetEnvoi.refuse);
    expect(sujet.rejectionCode, 'MAX_LOCKED');
    expect(sujet.questions, [q1]);
  });

  group('pull', () {
    test('un sujet local en attente n’est jamais écrasé', () async {
      await seed();
      await sujets.saveSujet(
        evaluationId: 'ev-1',
        sujet: const EvaluationSujetRow(questions: [q1], updatedAt: 3000),
      );

      final written = await sujets.applyPulledSujet(
        db,
        evaluationId: 'ev-1',
        sujet: const EvaluationSujetRow(questions: [q2]),
      );

      expect(written, isFalse);
      expect((await sujets.getSujet('ev-1'))!.questions, [q1]);
    });

    test('un sujet accusé est remplacé par celui du serveur', () async {
      await seed();

      await sujets.applyPulledSujet(
        db,
        evaluationId: 'ev-1',
        sujet: const EvaluationSujetRow(questions: [q2], dureeMinutes: 30),
      );

      final sujet = (await sujets.getSujet('ev-1'))!;
      expect(sujet.questions, [q2]);
      expect(sujet.dureeMinutes, 30);
      expect(sujet.toEntity().envoi, SujetEnvoi.envoye);
    });

    test('rafraîchir l’évaluation ne touche pas son sujet', () async {
      await seed();
      await sujets.saveSujet(
        evaluationId: 'ev-1',
        sujet: const EvaluationSujetRow(questions: [q1], updatedAt: 3000),
      );
      await sujets.markSujetSynced(evaluationId: 'ev-1', pushedUpdatedAt: 3000);

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
      expect((await sujets.getSujet('ev-1'))!.questions, [q1]);
    });
  });
}
