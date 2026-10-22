import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/depot/evaluation_depot_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/sujet/evaluation_view_applier.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/depot/depot_copie_row.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../../core/offline/offline_full_test_db.dart';

/// Les copies déposées par les parents (V180) : du champ `depots` de la vue
/// d'évaluation jusqu'à la table locale.
void main() {
  Map<String, dynamic> depot(
    String id,
    String studentId, {
    bool late = false,
  }) => {
    'id': id,
    'studentId': studentId,
    'depositedAt': '2026-10-20T14:05:00Z',
    'enRetard': late,
    'fichiers': [
      {
        'id': '$id-p2',
        'ordre': 2,
        'nom': 'page2.jpg',
        'mimeType': 'image/jpeg',
        'sizeBytes': 10,
        'sha256': 'b',
      },
      {
        'id': '$id-p1',
        'ordre': 1,
        'nom': 'page1.jpg',
        'mimeType': 'image/jpeg',
        'sizeBytes': 10,
        'sha256': 'a',
      },
      {'id': 'sans-empreinte', 'ordre': 3},
    ],
  };

  group('lecture du fil', () {
    test(
      'les pages sont rangées dans l ordre, une page mal décrite écartée',
      () {
        final depots = DepotCopieRow.listFromJson([
          depot('d1', 's1', late: true),
          {'id': 'sans-eleve'},
        ])!;
        expect(depots, hasLength(1));
        expect(depots.single.enRetard, isTrue);
        expect(depots.single.fichiers.map((f) => f.id), ['d1-p1', 'd1-p2']);
        // La page sans empreinte est comptée : la copie ne s'ouvrira pas.
        expect(depots.single.pagesEcartees, 1);
        expect(depots.single.isComplete, isFalse);
      },
    );

    test('champ absent ≠ aucune copie', () {
      expect(DepotCopieRow.listFromJson(null), isNull);
      expect(DepotCopieRow.listFromJson(const []), isEmpty);
    });

    test('aller-retour par la table', () {
      final copie = DepotCopieRow.listFromJson([depot('d1', 's1')])!.single;
      expect(DepotCopieRow.fromMap(DepotCopieRow.toMap('e1', copie)), copie);
    });
  });

  group('application', () {
    late Database db;
    late EvaluationViewApplier applier;
    late EvaluationDepotLocalDataSource depots;

    EvaluationDeltaDto view({List<Map<String, dynamic>>? copies}) =>
        EvaluationDeltaDto.fromJson({
          'id': 'e1',
          'coursId': 'c1',
          'type': 'DEVOIR',
          'date': '2026-10-20',
          'maxPoints': 20,
          'serverUpdatedAt': '2026-10-20T15:00:00Z',
          'modeRemise': 'EN_LIGNE',
          'depots': ?copies,
        });

    setUp(() async {
      db = await openFullOfflineDb();
      applier = EvaluationViewApplier.on(db);
      depots = EvaluationDepotLocalDataSource(db);
    });
    tearDown(() => db.close());

    test(
      'la liste du serveur remplace la locale : un dépôt remplacé part',
      () async {
        await applier.apply([
          view(copies: [depot('d1', 's1'), depot('d2', 's2')]),
        ], 1);
        await applier.apply([
          view(copies: [depot('d3', 's1')]),
        ], 2);

        final local = await depots.depotsOf('e1');
        expect(local.map((d) => d.id), ['d3']);
      },
    );

    test('une vue sans le champ garde les copies connues', () async {
      await applier.apply([
        view(copies: [depot('d1', 's1')]),
      ], 1);
      await applier.apply([view()], 2);

      expect(await depots.depotsOf('e1'), hasLength(1));
    });
  });

  test('un cours retiré emporte les copies de ses devoirs', () async {
    final db = await openFullOfflineDb();
    addTearDown(db.close);
    await db.insert('evaluation', {
      'id': 'e1',
      'cours_id': 'c1',
      'type': 'DEVOIR',
      'eval_date': 0,
      'max_points': 20,
      'poids': 1,
      'updated_at': 0,
    });
    await db.insert('evaluation_depot', {
      'id': 'd1',
      'evaluation_id': 'e1',
      'student_id': 's1',
    });

    await AcademicsLocalDataSource(db).evictCoursData('c1');

    expect(await db.query('evaluation_depot'), isEmpty);
  });
}
