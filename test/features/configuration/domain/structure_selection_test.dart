import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/structure_selection.dart';

CatalogSection _section(String code, {String? filiere, int courses = 20}) =>
    CatalogSection(
      officialCode: code,
      filiere: filiere,
      filiereAbregee: filiere?.substring(0, 3),
      libelle: code,
      codeOfficiel: 'IGE/$code',
      courseCount: courses,
    );

CatalogLevel _level(
  String code, {
  List<CatalogSection> sections = const [],
  List<String> warnings = const [],
  int defaultClassrooms = 1,
  bool defaultSelected = true,
}) => CatalogLevel(
  code: code,
  name: code,
  displayOrder: 1,
  defaultSelected: defaultSelected,
  defaultClassrooms: defaultClassrooms,
  sections: sections,
  warnings: warnings,
);

/// Le catalogue réel, dans sa forme qui compte : quatre cycles, dont un
/// préscolaire sans barème et des Humanités où les niveaux n'offrent PAS les
/// mêmes filières.
final _catalog = ProvisioningCatalog(
  version: '2026.1',
  country: 'CD',
  cycles: [
    CatalogCycle(
      code: 'MAT',
      name: 'Cycle Maternel',
      periodType: 'TRIMESTER',
      displayOrder: 1,
      defaultSelected: true,
      levels: [
        _level('M1', warnings: const ['NO_OFFICIAL_GRID']),
        _level('M2', warnings: const ['NO_OFFICIAL_GRID']),
      ],
    ),
    CatalogCycle(
      code: 'PRIM',
      name: 'Cycle Primaire',
      periodType: 'TRIMESTER',
      displayOrder: 2,
      defaultSelected: true,
      levels: [
        _level('P1', sections: [_section('DEGRE_1')]),
        _level('P6', sections: [_section('DEGRE_T')]),
      ],
    ),
    CatalogCycle(
      code: 'HG',
      name: 'Humanités Générales',
      periodType: 'SEMESTER',
      displayOrder: 4,
      defaultSelected: true,
      levels: [
        // HG1 porte QUATRE barèmes…
        _level(
          'HG1',
          sections: [
            _section('SCI_1', filiere: 'SCIENTIFIQUE', courses: 24),
            _section('LP_1', filiere: 'LATIN_PHILO'),
            _section('PED_1', filiere: 'PEDAGOGIE'),
            _section('TECH_1', filiere: 'TECHNIQUE'),
          ],
        ),
        // …HG2 n'en porte que trois.
        _level(
          'HG2',
          sections: [
            _section('SCI_2', filiere: 'SCIENTIFIQUE'),
            _section('LP_2', filiere: 'LATIN_PHILO'),
            _section('PED_2', filiere: 'PEDAGOGIE'),
          ],
        ),
      ],
    ),
  ],
);

CatalogLevel _levelOf(String code) => _catalog.cycles
    .expand((cycle) => cycle.levels)
    .firstWhere((level) => level.code == code);

CatalogCycle _cycleOf(String code) =>
    _catalog.cycles.firstWhere((cycle) => cycle.code == code);

void main() {
  group('la matrice n\'est pas un produit cartésien', () {
    test('un niveau à barèmes ouvre une colonne PAR barème', () {
      // HG1 : 4 colonnes. HG2 : 3. Sept, pas huit — les construire en
      // multipliant les niveaux par les filières du cycle en inventerait une
      // que le serveur refuserait en 422.
      expect(StructureSelection.columnsOf(_levelOf('HG1')), hasLength(4));
      expect(StructureSelection.columnsOf(_levelOf('HG2')), hasLength(3));
    });

    test('un niveau à barème unique n\'ouvre qu\'une colonne simple', () {
      // Une section sans filière, c'est du tronc commun : le compteur simple y
      // suffit, et une colonne « P1 × Degré 1 » n'apporterait rien.
      expect(StructureSelection.columnsOf(_levelOf('P1')), ['P1']);
    });

    test('un niveau sans aucun barème ouvre aussi une colonne simple', () {
      expect(StructureSelection.columnsOf(_levelOf('M1')), ['M1']);
    });

    test('la clé porte le code, jamais la position', () {
      // Un index se décalerait au premier barème ajouté au catalogue, et les
      // compteurs se retrouveraient sur la mauvaise filière.
      expect(
        StructureSelection.columnsOf(_levelOf('HG1')),
        containsAll(<String>['HG1|SCI_1', 'HG1|TECH_1']),
      );
    });
  });

  group('proposition par défaut', () {
    final proposition = StructureSelection.defaultFor(_catalog);

    test('tout est coché, une classe par colonne', () {
      // 2 maternelle + 2 primaire + 4 HG1 + 3 HG2 = 11 classes.
      expect(
        _catalog.cycles.fold<int>(
          0,
          (total, cycle) => total + proposition.classroomsOfCycle(cycle),
        ),
        11,
      );
    });

    test('chaque barème servi ouvre sa classe', () {
      expect(proposition.countFor('HG1|TECH_1'), 1);
      expect(proposition.countFor('HG2|SCI_2'), 1);
    });

    test('un niveau non pré-coché reste fermé', () {
      final catalog = ProvisioningCatalog(
        version: 'x',
        country: 'CD',
        cycles: [
          CatalogCycle(
            code: 'C',
            name: 'C',
            periodType: 'TRIMESTER',
            displayOrder: 1,
            defaultSelected: true,
            levels: [_level('A'), _level('B', defaultSelected: false)],
          ),
        ],
      );

      final selection = StructureSelection.defaultFor(catalog);
      expect(selection.countFor('A'), 1);
      expect(selection.countFor('B'), 0);
    });
  });

  group('compteurs', () {
    test('le plafond de l\'écran prime sur celui du serveur', () {
      // Le serveur en accepte seize par filière ; l'écran s'arrête à dix.
      // Laisser saisir jusqu'à seize pour se faire refuser au bout serait cruel.
      final selection = StructureSelection.empty.withCount('P1', 42);
      expect(selection.countFor('P1'), StructureSelection.maxPerColumn);
    });

    test('zéro efface la colonne plutôt que d\'y écrire 0', () {
      final selection = StructureSelection.empty
          .withCount('P1', 3)
          .withCount('P1', 0);
      expect(selection.counts.containsKey('P1'), isFalse);
    });

    test('une valeur négative vaut zéro', () {
      expect(StructureSelection.empty.withCount('P1', -5).countFor('P1'), 0);
    });

    test('cocher un niveau à barèmes rouvre TOUTES ses filières', () {
      // Et non « une classe » : sur un niveau à filières, cocher doit rendre
      // l'état de la première ouverture, pas un état que personne n'a choisi.
      final selection = StructureSelection.empty.withLevelChecked(
        _levelOf('HG1'),
        true,
      );
      expect(selection.classroomsOf(_levelOf('HG1')), 4);
    });

    test('décocher un niveau ferme toutes ses colonnes', () {
      final selection = StructureSelection.defaultFor(
        _catalog,
      ).withLevelChecked(_levelOf('HG1'), false);
      expect(selection.isLevelOpen(_levelOf('HG1')), isFalse);
      expect(selection.classroomsOf(_levelOf('HG2')), 3);
    });
  });

  group('réglage global du cycle', () {
    test('il n\'atteint pas les niveaux à barèmes', () {
      // « Trois classes » n'y veut rien dire tant qu'on n'a pas dit lesquelles,
      // et le serveur le refuserait.
      final selection = StructureSelection.defaultFor(
        _catalog,
      ).withCycleDefault(_cycleOf('HG'), 5);

      expect(selection.countFor('HG1|SCI_1'), 1);
      expect(selection.countFor('HG2|PED_2'), 1);
    });

    test('il applique la valeur aux niveaux de tronc commun', () {
      final selection = StructureSelection.defaultFor(
        _catalog,
      ).withCycleDefault(_cycleOf('PRIM'), 3);

      expect(selection.countFor('P1'), 3);
      expect(selection.countFor('P6'), 3);
    });

    test('il part de la valeur commune quand elle existe', () {
      final selection = StructureSelection.empty
          .withCount('P1', 2)
          .withCount('P6', 2);
      expect(selection.cycleDefaultOf(_cycleOf('PRIM')), 2);
    });

    test('il part de la moyenne arrondie quand elles divergent', () {
      // Partir de zéro donnerait l'impression que rien n'est ouvert ; partir de
      // un écraserait une saisie déjà faite dès qu'on touche la molette.
      final selection = StructureSelection.empty
          .withCount('P1', 1)
          .withCount('P6', 4);
      expect(selection.cycleDefaultOf(_cycleOf('PRIM')), 3);
    });

    test('un cycle sans niveau de tronc commun rend zéro', () {
      expect(
        StructureSelection.defaultFor(_catalog).cycleDefaultOf(_cycleOf('HG')),
        0,
      );
    });
  });

  group('corps de requête', () {
    test('un niveau à barèmes n\'envoie que ses sections', () {
      final cycles = StructureSelection.defaultFor(_catalog).toCycles(_catalog);
      final hg1 = cycles
          .firstWhere((cycle) => cycle.catalogCode == 'HG')
          .levels
          .firstWhere((level) => level.catalogCode == 'HG1');

      expect(hg1.classrooms, isNull);
      expect(hg1.sections, hasLength(4));
    });

    test('un cycle sans aucun niveau retenu est omis', () {
      // Un cycle retenu sans niveau rend 400.
      final selection = StructureSelection.defaultFor(
        _catalog,
      ).withCycleChecked(_cycleOf('MAT'), false);

      final cycles = selection.toCycles(_catalog);
      expect(cycles.map((cycle) => cycle.catalogCode), isNot(contains('MAT')));
      expect(cycles, hasLength(2));
    });

    test('une filière fermée disparaît, le niveau reste', () {
      final selection = StructureSelection.defaultFor(
        _catalog,
      ).withCount('HG1|TECH_1', 0);

      final hg1 = selection
          .toCycles(_catalog)
          .firstWhere((cycle) => cycle.catalogCode == 'HG')
          .levels
          .firstWhere((level) => level.catalogCode == 'HG1');

      expect(hg1.sections, hasLength(3));
      expect(
        hg1.sections.map((section) => section.officialCode),
        isNot(contains('TECH_1')),
      );
    });

    test('tout fermé produit un corps vide, pas des coquilles', () {
      expect(StructureSelection.empty.toCycles(_catalog), isEmpty);
    });
  });

  group('reprise d\'un brouillon', () {
    test('les compteurs reviennent sur leurs colonnes', () {
      const draft = ProvisioningRequest(
        cycles: [
          CycleInput(
            catalogCode: 'PRIM',
            levels: [LevelInput(catalogCode: 'P6', classrooms: 3)],
          ),
          CycleInput(
            catalogCode: 'HG',
            levels: [
              LevelInput(
                catalogCode: 'HG1',
                sections: [SectionInput(officialCode: 'SCI_1', classrooms: 2)],
              ),
            ],
          ),
        ],
      );

      final selection = StructureSelection.fromDraft(draft, _catalog);
      expect(selection.countFor('P6'), 3);
      expect(selection.countFor('HG1|SCI_1'), 2);
      expect(selection.countFor('HG1|LP_1'), 0);
    });

    test('un code que le catalogue ne connaît plus est abandonné', () {
      // Le garder ferait partir un code refusé en 422, et l'écran ne saurait
      // pas dire d'où il vient. Un brouillon vieux de plusieurs semaines n'a
      // pas à bloquer une mise en service.
      const draft = ProvisioningRequest(
        cycles: [
          CycleInput(
            catalogCode: 'ANCIEN',
            levels: [LevelInput(catalogCode: 'X9', classrooms: 4)],
          ),
        ],
      );

      expect(StructureSelection.fromDraft(draft, _catalog).counts, isEmpty);
    });

    test('un barème retiré du niveau est abandonné, les autres restent', () {
      const draft = ProvisioningRequest(
        cycles: [
          CycleInput(
            catalogCode: 'HG',
            levels: [
              LevelInput(
                catalogCode: 'HG1',
                sections: [
                  SectionInput(officialCode: 'SCI_1', classrooms: 2),
                  SectionInput(officialCode: 'DISPARU', classrooms: 5),
                ],
              ),
            ],
          ),
        ],
      );

      final selection = StructureSelection.fromDraft(draft, _catalog);
      expect(selection.countFor('HG1|SCI_1'), 2);
      expect(selection.counts.keys, hasLength(1));
    });

    test('un compteur simple sur un niveau devenu à barèmes est ignoré', () {
      // Le catalogue a changé sous le brouillon : rejouer le compteur simple
      // enverrait exactement le corps que le serveur refuse en 422.
      const draft = ProvisioningRequest(
        cycles: [
          CycleInput(
            catalogCode: 'HG',
            levels: [LevelInput(catalogCode: 'HG1', classrooms: 3)],
          ),
        ],
      );

      expect(StructureSelection.fromDraft(draft, _catalog).counts, isEmpty);
    });

    test('un aller-retour brouillon conserve la sélection', () {
      final origine = StructureSelection.defaultFor(_catalog);
      final draft = ProvisioningRequest(cycles: origine.toCycles(_catalog));

      expect(StructureSelection.fromDraft(draft, _catalog), origine);
    });
  });

  group('assiette proposable à l\'étape 4', () {
    test('seuls les niveaux qui ouvrent une classe sont facturables', () {
      // On ne facture pas un niveau qu'on n'ouvre pas.
      final selection = StructureSelection.defaultFor(
        _catalog,
      ).withLevelChecked(_levelOf('M1'), false);

      final codes = selection.openLevelCodes(_catalog);
      expect(codes, isNot(contains('M1')));
      expect(codes, containsAll(<String>['M2', 'P1', 'HG1']));
    });
  });
}
