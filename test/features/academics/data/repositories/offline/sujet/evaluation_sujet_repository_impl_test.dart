import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_sujet_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/sujet/evaluation_sujet_repository_impl.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';

import '../../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late EvaluationSujetRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    repo = EvaluationSujetRepositoryImpl(
      localDataSource: EvaluationSujetLocalDataSource(db),
      now: () => 7000,
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

  const q = SujetQuestion(id: 'q1', enonce: 'Q', points: 7);

  test('enregistre en attente, horodaté, avec le maximum ajusté', () async {
    final result = await repo.saveSujet(
      'ev-1',
      cadre: const EvaluationCadre(dureeMinutes: 45),
      questions: const [q],
      maxPoints: 7,
    );

    expect(
      result.getOrElse(() => const EvaluationSujet()).envoi,
      SujetEnvoi.enAttente,
    );
    final row = (await EvaluationSujetLocalDataSource(db).getSujet('ev-1'))!;
    expect(row.updatedAt, 7000);
    expect(row.questions, [q]);
    expect(
      (await AcademicsLocalDataSource(db).getEvaluation('ev-1'))!.maxPoints,
      7,
    );
  });

  test('évaluation absente : NotFoundFailure', () async {
    final result = await repo.saveSujet(
      'absente',
      cadre: const EvaluationCadre(),
      questions: const [],
    );
    expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
  });
}
