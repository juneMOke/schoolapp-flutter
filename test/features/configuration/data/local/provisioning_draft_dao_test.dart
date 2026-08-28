import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/data/local/provisioning_draft_dao.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';

void main() {
  late Database db;
  late ProvisioningDraftDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ProvisioningDraftDao(db);
  });

  tearDown(() async => db.close());

  ProvisioningRequest brouillonComplet() => ProvisioningRequest(
    academicYear: AcademicYearInput(
      name: '2026-2027',
      startDate: DateTime.utc(2026, 9, 1),
      endDate: DateTime.utc(2027, 6, 30),
    ),
    defaultClassroomsPerLevel: 1,
    cycles: const [
      CycleInput(
        catalogCode: 'PRIM',
        levels: [LevelInput(catalogCode: 'P1', classrooms: 2)],
      ),
      CycleInput(
        catalogCode: 'HG',
        levels: [
          LevelInput(
            catalogCode: 'HG1',
            sections: [
              SectionInput(officialCode: 'SCIENTIFIQUE_1', classrooms: 2),
              SectionInput(officialCode: 'PEDAGOGIE_1', classrooms: 1),
            ],
          ),
        ],
      ),
    ],
    fees: [
      FeeInput(
        feeCode: 'TUITION',
        label: 'Minerval',
        amountInCents: 68000,
        currency: 'USD',
        dueAt: DateTime.utc(2027, 6, 30, 23, 59, 59),
        appliesTo: const FeeScopeInput.allOpenedLevels(),
      ),
      FeeInput(
        feeCode: 'CANTEEN',
        label: 'Cantine',
        amountInCents: 800000,
        currency: 'CDF',
        dueAt: null,
        appliesTo: const FeeScopeInput(
          scope: FeeScope.levels,
          levelCatalogCodes: ['P6'],
        ),
      ),
    ],
  );

  group('aller-retour', () {
    test('un brouillon complet se relit à l\'identique', () async {
      await dao.save(
        schoolId: 'ecole-1',
        userId: 'user-1',
        request: brouillonComplet(),
        step: 3,
        maxStep: 4,
      );

      final relu = await dao.find(schoolId: 'ecole-1', userId: 'user-1');

      expect(relu, isNotNull);
      expect(relu!.step, 3);
      expect(relu.maxStep, 4);
      expect(relu.request, brouillonComplet());
    });

    test('un brouillon à moitié rempli se relit tel quel', () async {
      // C'est tout l'intérêt d'un encodage propre au brouillon : le modèle
      // réseau, lui, refuserait une requête sans année et omettrait les cycles
      // vides. Un brouillon doit se souvenir de ce qui n'est pas fini.
      const incomplet = ProvisioningRequest(
        cycles: [CycleInput(catalogCode: 'MAT', levels: [])],
      );

      await dao.save(
        schoolId: 'ecole-1',
        userId: 'user-1',
        request: incomplet,
        step: 1,
        maxStep: 1,
      );

      final relu = await dao.find(schoolId: 'ecole-1', userId: 'user-1');

      expect(relu!.request.academicYear, isNull);
      expect(relu.request.cycles.single.catalogCode, 'MAT');
      expect(relu.request.cycles.single.levels, isEmpty);
    });

    test('un second enregistrement remplace le premier', () async {
      await dao.save(
        schoolId: 'ecole-1',
        userId: 'user-1',
        request: brouillonComplet(),
        step: 2,
        maxStep: 2,
      );
      await dao.save(
        schoolId: 'ecole-1',
        userId: 'user-1',
        request: const ProvisioningRequest(),
        step: 1,
        maxStep: 3,
      );

      final relu = await dao.find(schoolId: 'ecole-1', userId: 'user-1');

      expect(relu!.request.cycles, isEmpty);
      expect(relu.step, 1);
      expect(relu.maxStep, 3);
    });
  });

  group('cloisonnement — une tablette, deux écoles', () {
    test('le brouillon d\'une autre école n\'est jamais relu', () async {
      // Ce brouillon aboutit à une écriture irréversible : le relire hors de
      // son école ferait activer la mauvaise.
      await dao.save(
        schoolId: 'ecole-A',
        userId: 'user-1',
        request: brouillonComplet(),
        step: 3,
        maxStep: 3,
      );

      expect(await dao.find(schoolId: 'ecole-B', userId: 'user-1'), isNull);
    });

    test('le brouillon d\'un autre utilisateur n\'est jamais relu', () async {
      await dao.save(
        schoolId: 'ecole-A',
        userId: 'user-1',
        request: brouillonComplet(),
        step: 3,
        maxStep: 3,
      );

      expect(await dao.find(schoolId: 'ecole-A', userId: 'user-2'), isNull);
    });

    test('deux écoles gardent chacune le sien', () async {
      await dao.save(
        schoolId: 'ecole-A',
        userId: 'user-1',
        request: brouillonComplet(),
        step: 4,
        maxStep: 4,
      );
      await dao.save(
        schoolId: 'ecole-B',
        userId: 'user-1',
        request: const ProvisioningRequest(),
        step: 0,
        maxStep: 0,
      );

      final a = await dao.find(schoolId: 'ecole-A', userId: 'user-1');
      final b = await dao.find(schoolId: 'ecole-B', userId: 'user-1');

      expect(a!.step, 4);
      expect(b!.step, 0);
      expect(a.request.cycles, isNotEmpty);
      expect(b.request.cycles, isEmpty);
    });

    test('effacer n\'atteint que le brouillon visé', () async {
      await dao.save(
        schoolId: 'ecole-A',
        userId: 'user-1',
        request: brouillonComplet(),
        step: 1,
        maxStep: 1,
      );
      await dao.save(
        schoolId: 'ecole-B',
        userId: 'user-1',
        request: brouillonComplet(),
        step: 1,
        maxStep: 1,
      );

      await dao.delete(schoolId: 'ecole-A', userId: 'user-1');

      expect(await dao.find(schoolId: 'ecole-A', userId: 'user-1'), isNull);
      expect(await dao.find(schoolId: 'ecole-B', userId: 'user-1'), isNotNull);
    });
  });

  group('robustesse', () {
    test('un payload illisible vaut « pas de brouillon »', () async {
      // Le format peut changer entre deux versions de l'application. Refuser
      // d'ouvrir l'assistant pour cette raison enfermerait l'agent hors du seul
      // écran capable de le débloquer.
      await db.insert('provisioning_drafts', {
        'school_id': 'ecole-1',
        'user_id': 'user-1',
        'payload': 'ceci n\'est pas du JSON',
        'step': 2,
        'max_step': 2,
        'updated_at': 0,
      });

      expect(await dao.find(schoolId: 'ecole-1', userId: 'user-1'), isNull);
    });

    test(
      'un payload JSON mais non conforme vaut « pas de brouillon »',
      () async {
        await db.insert('provisioning_drafts', {
          'school_id': 'ecole-1',
          'user_id': 'user-1',
          'payload': '[1, 2, 3]',
          'step': 0,
          'max_step': 0,
          'updated_at': 0,
        });

        expect(await dao.find(schoolId: 'ecole-1', userId: 'user-1'), isNull);
      },
    );

    test('effacer un brouillon inexistant ne lève pas', () async {
      await dao.delete(schoolId: 'inconnue', userId: 'personne');
    });
  });
}
