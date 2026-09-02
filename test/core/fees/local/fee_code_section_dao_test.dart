import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_dao.dart';
import 'package:school_app_flutter/core/fees/local/fee_code_section_local_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../features/offline_full_db.dart';

/// Les titres de sections de frais en local (GF-0).
///
/// Trois propriétés à tenir, et chacune a son contre-exemple :
///  - **la purge est scopée par école** — la table n'a pas d'année, donc aucun
///    filtre ne transformerait une erreur de scope en « liste vide » : les frais
///    de l'école d'à côté se renommeraient tout seuls en nature localisée ;
///  - **`active` ne filtre RIEN à la lecture** — masquer dit « ne me la propose
///    plus à la saisie », jamais « ne sais plus la nommer » ;
///  - **une ligne sans titre ne s'écrit pas** — elle remplacerait la nature
///    localisée par du blanc, ce qui est pire que le repli.
void main() {
  late Database db;
  late FeeCodeSectionDao dao;

  FeeCodeSectionLocalModel section(
    String schoolId, {
    String code = 'TUITION',
    String label = 'Frais scolaires',
    bool active = true,
    int sortOrder = 0,
  }) => FeeCodeSectionLocalModel(
    schoolId: schoolId,
    code: code,
    label: label,
    active: active,
    sortOrder: sortOrder,
    syncedAt: 1_700_000_000_000,
  );

  setUp(() async {
    db = await openFullOfflineDb();
    dao = FeeCodeSectionDao(db);
  });
  tearDown(() async => db.close());

  group('replaceForSchool', () {
    test('remplace le catalogue de l\'école, pas celui des autres', () async {
      await dao.replaceForSchool([section('A')], schoolId: 'A');
      await dao.replaceForSchool([
        section('B', label: 'Minerval B'),
      ], schoolId: 'B');

      await dao.replaceForSchool([
        section('A', label: 'Frais de scolarité'),
      ], schoolId: 'A');

      expect(await dao.titlesForSchool('A'), {'TUITION': 'Frais de scolarité'});
      expect(
        await dao.titlesForSchool('B'),
        {'TUITION': 'Minerval B'},
        reason:
            'La purge doit être scopée : sinon le poste d\'à côté verrait ses '
            'frais se renommer sans que rien ne l\'explique.',
      );
    });

    test('école vide : on ne touche à rien', () async {
      await dao.replaceForSchool([section('A')], schoolId: 'A');

      await dao.replaceForSchool([
        section('', code: 'CANTEEN', label: 'Cantine'),
      ], schoolId: '');

      expect(await dao.titlesForSchool('A'), {'TUITION': 'Frais scolaires'});
      expect(
        await db.query('ref_fee_code_sections', where: "school_id = ''"),
        isEmpty,
        reason:
            'Une ligne sous la clé vide serait invisible à toute lecture '
            'scopée.',
      );
    });

    test(
      'un catalogue vide purge : c\'est une réponse, pas une absence',
      () async {
        await dao.replaceForSchool([section('A')], schoolId: 'A');

        await dao.replaceForSchool(const [], schoolId: 'A');

        expect(await dao.titlesForSchool('A'), isEmpty);
      },
    );

    test('les lignes sans code ni titre sont écartées à l\'écriture', () async {
      await dao.replaceForSchool([
        section('A'),
        section('A', code: 'CANTEEN', label: '   '),
        section('A', code: '  ', label: 'Orphelin'),
      ], schoolId: 'A');

      expect(await dao.titlesForSchool('A'), {'TUITION': 'Frais scolaires'});
    });
  });

  group('titlesForSchool', () {
    test('une section MASQUÉE garde son titre', () async {
      await dao.replaceForSchool([
        section('A', code: 'BOARDING', label: 'Internat', active: false),
      ], schoolId: 'A');

      expect(
        await dao.titlesForSchool('A'),
        {'BOARDING': 'Internat'},
        reason:
            'Une créance posée avant le masquage existe toujours, et c\'est '
            'elle qu\'on affiche.',
      );
    });

    test('le code est normalisé en majuscules', () async {
      await dao.replaceForSchool([
        section('A', code: 'tuition', label: 'Frais scolaires'),
      ], schoolId: 'A');

      expect(await dao.titlesForSchool('A'), {'TUITION': 'Frais scolaires'});
    });

    test(
      'sans école, ou sans ligne, une table vide — jamais d\'erreur',
      () async {
        expect(await dao.titlesForSchool(''), isEmpty);
        expect(await dao.titlesForSchool('inconnue'), isEmpty);
      },
    );
  });
}
