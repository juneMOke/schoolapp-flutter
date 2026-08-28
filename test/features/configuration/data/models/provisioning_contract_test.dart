import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_catalog_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_plan_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_request_model.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';

void main() {
  group('sérialisation de dueAt — deux routes, deux formats', () {
    final echeance = DateTime.utc(2027, 6, 30, 23, 59, 59);

    test('/provisioning/apply exige le suffixe Z', () {
      // Sans lui, le corps est illisible côté serveur et l'appel rend 400.
      expect(
        ProvisioningInstant.toUtcInstant(echeance),
        '2027-06-30T23:59:59Z',
      );
    });

    test('/finance/tariffs interdit le suffixe Z', () {
      // Le serveur y attend un LocalDateTime. Même notion, autre format : dette
      // de contrat assumée côté serveur, isolée ici en deux fonctions nommées.
      expect(
        ProvisioningInstant.toLocalDateTime(echeance),
        '2027-06-30T23:59:59',
      );
    });

    test('une échéance saisie au jour court jusqu\'au bout de ce jour', () {
      // La ramener à minuit ferait expirer un frais une journée trop tôt.
      final fin = ProvisioningInstant.endOfDayUtc(DateTime(2027, 6, 30));
      expect(ProvisioningInstant.toUtcInstant(fin), '2027-06-30T23:59:59Z');
    });

    test('la lecture accepte les deux formes', () {
      expect(ProvisioningInstant.parse('2027-06-30T23:59:59Z'), isNotNull);
      expect(ProvisioningInstant.parse('2027-06-30T23:59:59'), isNotNull);
    });

    test('une valeur illisible rend null plutôt que d\'écrouler un plan', () {
      expect(ProvisioningInstant.parse('bientôt'), isNull);
      expect(ProvisioningInstant.parse(null), isNull);
      expect(ProvisioningInstant.parse(42), isNull);
    });
  });

  group('corps envoyé à /provisioning/apply', () {
    final annee = AcademicYearInput(
      name: '2026-2027',
      startDate: DateTime.utc(2026, 9, 1),
      endDate: DateTime.utc(2027, 6, 30),
    );

    test('un niveau à sections n\'envoie JAMAIS de compteur simple', () {
      // Les deux ensemble rendent 422 (« compteur et sections en conflit »).
      // L'interface doit rendre le cas inatteignable ; cette conversion est le
      // dernier filet avant le réseau.
      final body = ProvisioningRequestModel.fromEntity(
        ProvisioningRequest(
          academicYear: annee,
          cycles: const [
            CycleInput(
              catalogCode: 'HG',
              levels: [
                LevelInput(
                  catalogCode: 'HG1',
                  classrooms: 3,
                  sections: [
                    SectionInput(officialCode: 'SCIENTIFIQUE_1', classrooms: 2),
                  ],
                ),
              ],
            ),
          ],
        ),
      ).toJson();

      final niveau =
          (body['cycles'] as List).first['levels'][0] as Map<String, dynamic>;
      expect(niveau.containsKey('classrooms'), isFalse);
      expect(niveau['sections'], hasLength(1));
    });

    test('un niveau de tronc commun n\'envoie pas de sections', () {
      final body = ProvisioningRequestModel.fromEntity(
        ProvisioningRequest(
          academicYear: annee,
          cycles: const [
            CycleInput(
              catalogCode: 'PRIM',
              levels: [LevelInput(catalogCode: 'P1', classrooms: 2)],
            ),
          ],
        ),
      ).toJson();

      final niveau =
          (body['cycles'] as List).first['levels'][0] as Map<String, dynamic>;
      expect(niveau['classrooms'], 2);
      expect(niveau.containsKey('sections'), isFalse);
    });

    test('un cycle sans aucun niveau est omis entièrement', () {
      // Un cycle retenu sans niveau rend 400. Décocher un cycle doit le faire
      // disparaître du corps, pas y laisser une coquille vide.
      final body = ProvisioningRequestModel.fromEntity(
        ProvisioningRequest(
          academicYear: annee,
          cycles: const [
            CycleInput(catalogCode: 'MAT', levels: []),
            CycleInput(
              catalogCode: 'PRIM',
              levels: [LevelInput(catalogCode: 'P1', classrooms: 1)],
            ),
          ],
        ),
      ).toJson();

      final cycles = body['cycles'] as List;
      expect(cycles, hasLength(1));
      expect(cycles.first['catalogCode'], 'PRIM');
    });

    test('« tous les niveaux ouverts » n\'emporte aucune liste', () {
      // Le serveur résout l'assiette depuis la structure : la garder juste même
      // si le promoteur ajoute un niveau APRÈS avoir saisi le frais.
      final body = ProvisioningRequestModel.fromEntity(
        ProvisioningRequest(
          academicYear: annee,
          cycles: const [
            CycleInput(
              catalogCode: 'PRIM',
              levels: [LevelInput(catalogCode: 'P1', classrooms: 1)],
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
          ],
        ),
      ).toJson();

      final assiette =
          (body['fees'] as List).first['appliesTo'] as Map<String, dynamic>;
      expect(assiette['scope'], 'ALL_OPENED_LEVELS');
      expect(assiette.containsKey('levelCatalogCodes'), isFalse);
      expect((body['fees'] as List).first['dueAt'], '2027-06-30T23:59:59Z');
    });

    test('sans année, la conversion refuse avant le réseau', () {
      // La simulation valide l'année en premier : partir quand même ne
      // rapporterait qu'un 400 et une fausse alerte au journal serveur.
      expect(
        () => ProvisioningRequestModel.fromEntity(
          const ProvisioningRequest(cycles: []),
        ),
        throwsStateError,
      );
    });
  });

  group('lecture du catalogue', () {
    test('cycles et niveaux sont rendus dans leur ordre d\'affichage', () {
      // L'ordre est une donnée du référentiel : s'en remettre à l'ordre du
      // tableau JSON ferait dépendre l'écran d'un détail de sérialisation.
      final catalogue = ProvisioningCatalogModel.fromJson(
        jsonDecode('''
        {"version":"2026.1","country":"CD","cycles":[
          {"code":"HG","name":"Humanités Générales","periodType":"SEMESTER",
           "displayOrder":4,"defaultSelected":true,"levels":[]},
          {"code":"MAT","name":"Cycle Maternel","periodType":"TRIMESTER",
           "displayOrder":1,"defaultSelected":true,"levels":[
             {"code":"M2","name":"2ème Maternelle","displayOrder":2,
              "defaultSelected":true,"defaultClassrooms":1,"sections":[],
              "warnings":["NO_OFFICIAL_GRID"]},
             {"code":"M1","name":"1ère Maternelle","displayOrder":1,
              "defaultSelected":true,"defaultClassrooms":1,"sections":[],
              "warnings":["NO_OFFICIAL_GRID"]}]}]}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(catalogue.cycles.map((c) => c.code), ['MAT', 'HG']);
      expect(catalogue.cycles.first.levels.map((l) => l.code), ['M1', 'M2']);
    });

    test('l\'absence de barème se lit dans warnings, pas dans sections', () {
      // La liste des codes peut s'enrichir : la déduire de `sections.isEmpty`
      // marcherait aujourd'hui et mentirait au premier code ajouté.
      final niveau = CatalogLevelModel.fromJson(
        jsonDecode('''
        {"code":"M1","name":"1ère Maternelle","displayOrder":1,
         "defaultSelected":true,"defaultClassrooms":1,"sections":[],
         "warnings":["NO_OFFICIAL_GRID"]}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(niveau.hasNoOfficialGrid, isTrue);
      expect(niveau.hasMultipleSections, isFalse);
    });

    test('filiereAbregee absente ne casse rien', () {
      // Un serveur qui n'a pas encore livré le lot « nommage » ne sert pas ce
      // champ. Le nom des classes est lu du plan, donc rien ne dépend de lui
      // dans l'assistant.
      final section = CatalogSectionModel.fromJson(
        jsonDecode('''
        {"officialCode":"SCIENTIFIQUE_1","filiere":"SCIENTIFIQUE",
         "libelle":"Humanités Scientifiques","codeOfficiel":"IGE/P.S/012",
         "courseCount":24}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(section.filiereAbregee, isNull);
      expect(section.filiere, 'SCIENTIFIQUE');
      expect(section.courseCount, 24);
    });

    test('un champ inconnu du client est ignoré en silence', () {
      final catalogue = ProvisioningCatalogModel.fromJson(
        jsonDecode('''
        {"version":"2027.1","country":"CD","cycles":[],
         "nouveauChamp":"que ce client ne connaît pas"}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(catalogue.version, '2027.1');
    });
  });

  group('lecture du plan', () {
    test('les comptes viennent du serveur, y compris les cours', () {
      final plan = ProvisioningPlanModel.fromJson(
        jsonDecode('''
        {"dryRun":true,"academicYearId":null,"academicYearName":"2026-2027",
         "counts":{"cycles":4,"levels":15,"classrooms":20,"courses":312,"fees":21},
         "cycles":[],"fees":[],"warnings":[]}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(plan.counts.classrooms, 20);
      expect(plan.counts.courses, 312);
      expect(plan.counts.fees, 21);
      expect(plan.academicYearId, isNull);
    });

    test('des comptes absents valent zéro, jamais « inconnu »', () {
      final plan = ProvisioningPlanModel.fromJson(
        jsonDecode('{"dryRun":true}') as Map<String, dynamic>,
      ).toEntity();

      expect(plan.counts.classrooms, 0);
      expect(plan.cycles, isEmpty);
    });

    test('le nom d\'une classe est lu, pas reconstruit', () {
      // Il vaut pour les listes, les bulletins et les reçus : le fabriquer côté
      // client serait un mensonge à usage unique.
      final plan = ProvisioningPlanModel.fromJson(
        jsonDecode('''
        {"dryRun":true,"counts":{"cycles":1,"levels":1,"classrooms":2,
          "courses":34,"fees":0},
         "cycles":[{"catalogCode":"HG","name":"Humanités Générales",
           "periodType":"SEMESTER","id":null,"levels":[
             {"catalogCode":"HG1","name":"1ère Année Humanités","id":null,
              "classrooms":[
                {"name":"1ère Année Humanités Sci A","id":null,
                 "officialCode":"SCIENTIFIQUE_1","filiere":"SCIENTIFIQUE",
                 "grilleId":"g-1","courseCount":24},
                {"name":"1ère Année Humanités Péd","id":null,
                 "officialCode":"PEDAGOGIE_1","filiere":"PEDAGOGIE",
                 "grilleId":"g-2","courseCount":10}]}]}],
         "fees":[],"warnings":[]}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      final classes = plan.cycles.first.levels.first.classrooms;
      expect(classes.map((c) => c.name), [
        '1ère Année Humanités Sci A',
        '1ère Année Humanités Péd',
      ]);
      expect(classes.first.grilleId, 'g-1');
    });

    test('un tarif par niveau de l\'assiette', () {
      // Dissymétrie à ne pas perdre : un minerval saisi une fois sur deux
      // niveaux apparaît une fois à l'écran et deux fois ici.
      final plan = ProvisioningPlanModel.fromJson(
        jsonDecode('''
        {"dryRun":true,"counts":{"cycles":1,"levels":2,"classrooms":2,
          "courses":0,"fees":2},
         "cycles":[],"warnings":[],
         "fees":[
           {"feeCode":"TUITION","label":"Minerval","amountInCents":68000,
            "currency":"USD","dueAt":"2027-06-30T23:59:59Z",
            "levelCatalogCode":"P5","id":null},
           {"feeCode":"TUITION","label":"Minerval","amountInCents":68000,
            "currency":"USD","dueAt":"2027-06-30T23:59:59Z",
            "levelCatalogCode":"P6","id":null}]}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(plan.fees, hasLength(2));
      expect(plan.counts.fees, 2);
      expect(plan.fees.map((f) => f.levelCatalogCode), ['P5', 'P6']);
      expect(plan.fees.first.dueAt, isNotNull);
    });

    test('les avertissements portent leur message rédigé', () {
      // Servis en français : les afficher tels quels, ne pas les traduire, et
      // surtout ne pas les tester — seul le code est stable.
      final plan = ProvisioningPlanModel.fromJson(
        jsonDecode('''
        {"dryRun":true,"cycles":[],"fees":[],
         "warnings":[{"code":"NO_OFFICIAL_GRID","catalogCode":"M1",
           "message":"Aucun barème officiel pour « 1ère Maternelle »."}]}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(
        plan.warnings.single.code,
        ProvisioningWarningCodes.noOfficialGrid,
      );
      expect(plan.warnings.single.catalogCode, 'M1');
      expect(plan.warnings.single.message, contains('1ère Maternelle'));
    });
  });
}
