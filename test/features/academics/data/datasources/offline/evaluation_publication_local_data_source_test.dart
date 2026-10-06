import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_publication_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

void main() {
  late Database db;
  late EvaluationPublicationLocalDataSource publications;

  setUp(() async {
    db = await openFullOfflineDb();
    publications = EvaluationPublicationLocalDataSource(db);
    await AcademicsLocalDataSource(db).applyPulledEvaluations(const [
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

  final etat = PublicationEtat(
    publishedAt: DateTime.utc(2026, 10, 6, 8),
    updatedAt: DateTime.utc(2026, 10, 7, 9),
    revision: 2,
  );

  test('aucune publication par défaut', () async {
    expect(
      await publications.getPublications('ev-1'),
      EvaluationPublications.none,
    );
  });

  test('poser une publication laisse les deux autres', () async {
    await publications.setPublication('ev-1', PublicationKind.sujet, etat);
    await publications.setPublication('ev-1', PublicationKind.notes, etat);
    await publications.setPublication('ev-1', PublicationKind.sujet, null);

    final read = await publications.getPublications('ev-1');
    expect(read.sujet, isNull);
    expect(read.corrige, isNull);
    expect(read.notes, etat);
  });

  test('une évaluation absente ne lève pas', () async {
    await publications.setPublication('absente', PublicationKind.sujet, etat);
    expect(
      await publications.getPublications('absente'),
      EvaluationPublications.none,
    );
  });
}
