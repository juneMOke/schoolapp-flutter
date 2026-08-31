import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/reduction_catalog_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/reduction_catalog_local_models.dart';

import '../../offline_full_db.dart';

/// Barème de réductions (ADR-021 V1) — écriture par le pull, lecture au guichet.
///
/// Deux propriétés, et une seule vraiment dangereuse : **la purge est scopée par
/// école**. Ces tables n'ont pas d'année, donc aucun filtre d'année ne viendra
/// transformer une erreur de scope en « liste vide » — elle se traduirait
/// directement par la perte du barème de l'école d'à côté.
void main() {
  late Database db;
  late ReductionCatalogDao dao;

  ReductionTypeLocalModel type(
    String schoolId,
    String code, {
    String label = 'Libellé',
    bool active = true,
  }) => ReductionTypeLocalModel(
    schoolId: schoolId,
    code: code,
    label: label,
    active: active,
  );

  ReductionLineLocalModel line(
    String schoolId,
    String code, {
    String feeCode = 'MINERVAL',
  }) => ReductionLineLocalModel(
    schoolId: schoolId,
    reductionCode: code,
    feeCode: feeCode,
    percentage: 50,
  );

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ReductionCatalogDao(db);
  });
  tearDown(() async => db.close());

  group('replaceForSchool', () {
    test('remplace le barème de l\'école, pas celui des autres', () async {
      await dao.replaceForSchool(
        [type('A', 'STAFF_CHILD')],
        [line('A', 'STAFF_CHILD')],
        schoolId: 'A',
      );
      await dao.replaceForSchool(
        [type('B', 'SIBLING')],
        [line('B', 'SIBLING')],
        schoolId: 'B',
      );

      // Le pull de A repasse avec un barème réduit à rien : B ne doit pas
      // bouger d'une ligne. Sans le scope, le guichet de B verrait sa liste se
      // vider sans que rien ne l'explique.
      await dao.replaceForSchool(const [], const [], schoolId: 'A');

      expect(await dao.grantableForSchool('A'), isEmpty);
      expect((await dao.grantableForSchool('B')).single.code, 'SIBLING');
    });

    test('le remplacement est intégral, pas un cumul', () async {
      await dao.replaceForSchool(
        [type('A', 'STAFF_CHILD'), type('A', 'SIBLING')],
        [line('A', 'STAFF_CHILD'), line('A', 'SIBLING')],
        schoolId: 'A',
      );

      // STAFF_CHILD retiré côté serveur : il ne doit pas rester fantôme.
      await dao.replaceForSchool(
        [type('A', 'SIBLING')],
        [line('A', 'SIBLING')],
        schoolId: 'A',
      );

      expect((await dao.grantableForSchool('A')).map((r) => r.code), [
        'SIBLING',
      ]);
    });

    test('école non résolue → aucune écriture, aucune purge', () async {
      await dao.replaceForSchool(
        [type('A', 'STAFF_CHILD')],
        [line('A', 'STAFF_CHILD')],
        schoolId: 'A',
      );

      // Purger sous la clé '' effacerait le barème d'une base héritée ;
      // insérer sous cette clé le rendrait invisible à toute lecture scopée.
      await dao.replaceForSchool(
        [type('', 'AUTRE')],
        [line('', 'AUTRE')],
        schoolId: '',
      );

      expect((await dao.grantableForSchool('A')).single.code, 'STAFF_CHILD');
      expect(await db.query('ref_reduction_types'), hasLength(1));
    });
  });

  group('grantableForSchool', () {
    test('un type sans ligne de barème n\'est pas proposé', () async {
      await dao.replaceForSchool(
        [type('A', 'STAFF_CHILD'), type('A', 'VIDE')],
        // Rien pour VIDE : il ne réduira jamais rien. Le taux étant masqué à
        // l'écran, il serait indiscernable d'un type qui réduit — on le
        // cocherait de bonne foi et la V2 hériterait d'un octroi vide.
        [line('A', 'STAFF_CHILD')],
        schoolId: 'A',
      );

      expect((await dao.grantableForSchool('A')).map((r) => r.code), [
        'STAFF_CHILD',
      ]);
    });

    test('un type inactif n\'est pas proposé', () async {
      await dao.replaceForSchool(
        [type('A', 'STAFF_CHILD', active: false)],
        [line('A', 'STAFF_CHILD')],
        schoolId: 'A',
      );

      expect(await dao.grantableForSchool('A'), isEmpty);
    });

    test('la ligne d\'une AUTRE école ne rend pas un type proposable', () async {
      await dao.replaceForSchool(
        [type('A', 'STAFF_CHILD')],
        const [],
        schoolId: 'A',
      );
      await dao.replaceForSchool(
        [type('B', 'STAFF_CHILD')],
        [line('B', 'STAFF_CHILD')],
        schoolId: 'B',
      );

      // Le `EXISTS` joint sur (school_id, reduction_code) : sans le school_id,
      // le barème de B rendrait le type vide de A proposable.
      expect(await dao.grantableForSchool('A'), isEmpty);
    });

    test('tri par libellé', () async {
      await dao.replaceForSchool(
        [
          type('A', 'Z_CODE', label: 'Alpha'),
          type('A', 'A_CODE', label: 'Zoulou'),
        ],
        [line('A', 'Z_CODE'), line('A', 'A_CODE')],
        schoolId: 'A',
      );

      expect((await dao.grantableForSchool('A')).map((r) => r.label), [
        'Alpha',
        'Zoulou',
      ]);
    });

    test(
      'école non résolue → liste vide, pas une lecture non scopée',
      () async {
        await dao.replaceForSchool(
          [type('A', 'STAFF_CHILD')],
          [line('A', 'STAFF_CHILD')],
          schoolId: 'A',
        );

        expect(await dao.grantableForSchool(''), isEmpty);
      },
    );
  });
}
