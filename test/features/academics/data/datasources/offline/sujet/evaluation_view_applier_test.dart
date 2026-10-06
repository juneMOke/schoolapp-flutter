import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_copie_log_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_publication_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_view_applier.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

import '../../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late EvaluationViewApplier applier;

  setUp(() async {
    db = await openFullOfflineDb();
    applier = EvaluationViewApplier.on(db);
  });
  tearDown(() => db.close());

  EvaluationDeltaDto view({String enonce = 'Serveur'}) =>
      EvaluationDeltaDto.fromJson({
        'id': 'ev-1',
        'coursId': 'c-1',
        'type': 'DEVOIR',
        'date': '2026-10-14',
        'maxPoints': 20,
        'poids': 2,
        'sousPeriodeId': 'sp-1',
        'serverUpdatedAt': '2026-10-06T09:00:00Z',
        'titre': 'Devoir 1',
        'sujetClientUpdatedAt': '2026-10-06T08:00:00Z',
        'questions': [
          {'id': 'q1', 'ordre': 1, 'enonce': enonce, 'points': 20},
        ],
        'copieLog': [
          {
            'id': 'l-1',
            'kind': 'SHARE',
            'canal': 'WHATSAPP',
            'corrige': false,
            'occurredAt': '2026-10-06T10:00:00Z',
          },
        ],
        'publication': {
          'sujet': {'publishedAt': '2026-10-06T11:00:00Z', 'revision': 1},
        },
      });

  test(
    'matérialise l’évaluation, son sujet, son journal, ses publications',
    () async {
      await applier.apply([view()], 1000);

      final sujet = (await EvaluationSujetLocalDataSource(
        db,
      ).getSujet('ev-1'))!;
      expect(sujet.questions.single.enonce, 'Serveur');
      expect(
        await EvaluationCopieLogLocalDataSource(db).getForEvaluation('ev-1'),
        hasLength(1),
      );
      final pubs = await EvaluationPublicationLocalDataSource(
        db,
      ).getPublications('ev-1');
      expect(pubs.sujet!.revision, 1);
    },
  );

  test('un brouillon local en attente survit au pull', () async {
    await applier.apply([view()], 1000);
    await EvaluationSujetLocalDataSource(db).saveSujet(
      evaluationId: 'ev-1',
      sujet: const EvaluationSujetRow(
        questions: [SujetQuestion(id: 'q1', enonce: 'Local', points: 20)],
        updatedAt: 9000,
      ),
    );

    await applier.apply([view(enonce: 'Plus tard')], 2000);

    final sujet = (await EvaluationSujetLocalDataSource(db).getSujet('ev-1'))!;
    expect(sujet.questions.single.enonce, 'Local');
  });

  test('rejouer la même page ne change rien', () async {
    await applier.apply([view()], 1000);
    await applier.apply([view()], 1000);
    expect(
      await EvaluationCopieLogLocalDataSource(db).getForEvaluation('ev-1'),
      hasLength(1),
    );
  });
}
