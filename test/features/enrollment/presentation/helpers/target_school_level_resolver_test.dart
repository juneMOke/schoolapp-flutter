import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/target_school_level_resolver.dart';

SchoolLevel _level(String id, String name, int order) => SchoolLevel(
  id: id,
  name: name,
  code: id,
  displayOrder: order,
  splitIntoClassrooms: false,
);

SchoolLevelGroup _group(String id, String name, int order) =>
    SchoolLevelGroup(id: id, name: name, code: id, displayOrder: order);

void main() {
  group('resolveTargetSchoolLevel', () {
    // Cycle "Primaire" (order 1) : 1ère(1), 2ème(2), 3ème(3) Primaire.
    // Cycle "Secondaire" (order 2) : 1ère(1), 2ème(2) Secondaire.
    // Ids DÉLIBÉRÉMENT différents des libellés : les ids du référentiel ne
    // sont PAS stables d'une année sur l'autre (rejoués à chaque pull), seul
    // le libellé l'est — c'est tout l'objet de ce fichier de test.
    final groups = [
      SchoolLevelGroupBundle(
        group: _group('grp-1', 'Primaire', 1),
        levels: [
          _level('lvl-1', '1ère Primaire', 1),
          _level('lvl-2', '2ème Primaire', 2),
          _level('lvl-3', '3ème Primaire', 3),
        ],
      ),
      SchoolLevelGroupBundle(
        group: _group('grp-2', 'Secondaire', 2),
        levels: [
          _level('lvl-4', '1ère Secondaire', 1),
          _level('lvl-5', '2ème Secondaire', 2),
        ],
      ),
    ];

    test('matching par LABEL et non par id : id précédent différent, '
        'libellé identique → trouvé', () {
      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: groups,
        previousSchoolLevelLabel: '1ère Primaire',
        previousSchoolLevelGroupLabel: 'Primaire',
        validatedPreviousYear: true,
      );

      expect(
        result,
        const TargetSchoolLevelResolution(
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-2',
        ),
      );
    });

    test('insensible à la casse et aux accents', () {
      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: groups,
        previousSchoolLevelLabel: '1ERE primaire',
        previousSchoolLevelGroupLabel: 'PRIMAIRE',
        validatedPreviousYear: true,
      );

      expect(
        result,
        const TargetSchoolLevelResolution(
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-2',
        ),
      );
    });

    test('« contient » : le libellé courant peut porter un suffixe (ex. code) '
        'sans casser la correspondance', () {
      final withSuffix = [
        SchoolLevelGroupBundle(
          group: _group('grp-1', 'Primaire', 1),
          levels: [
            _level('lvl-1', '1ère Primaire (P1)', 1),
            _level('lvl-2', '2ème Primaire (P2)', 2),
          ],
        ),
      ];

      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: withSuffix,
        previousSchoolLevelLabel: '1ère Primaire',
        previousSchoolLevelGroupLabel: 'Primaire',
        validatedPreviousYear: true,
      );

      expect(
        result,
        const TargetSchoolLevelResolution(
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-2',
        ),
      );
    });

    test(
      'dernier niveau du cycle + validé → premier niveau du cycle suivant',
      () {
        final result = resolveTargetSchoolLevel(
          schoolLevelGroups: groups,
          previousSchoolLevelLabel: '3ème Primaire',
          previousSchoolLevelGroupLabel: 'Primaire',
          validatedPreviousYear: true,
        );

        expect(
          result,
          const TargetSchoolLevelResolution(
            schoolLevelGroupId: 'grp-2',
            schoolLevelId: 'lvl-4',
          ),
        );
      },
    );

    test(
      'dernier niveau du dernier cycle + validé → reste sur la même classe',
      () {
        final result = resolveTargetSchoolLevel(
          schoolLevelGroups: groups,
          previousSchoolLevelLabel: '2ème Secondaire',
          previousSchoolLevelGroupLabel: 'Secondaire',
          validatedPreviousYear: true,
        );

        expect(
          result,
          const TargetSchoolLevelResolution(
            schoolLevelGroupId: 'grp-2',
            schoolLevelId: 'lvl-5',
          ),
        );
      },
    );

    test('NON validé → redouble, prioritaire sur la progression', () {
      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: groups,
        previousSchoolLevelLabel: '1ère Primaire',
        previousSchoolLevelGroupLabel: 'Primaire',
        validatedPreviousYear: false,
      );

      expect(
        result,
        const TargetSchoolLevelResolution(
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-1',
        ),
      );
    });

    test('NON validé + dernier niveau du cycle → reste quand même sur la '
        'même classe (pas de saut de cycle)', () {
      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: groups,
        previousSchoolLevelLabel: '3ème Primaire',
        previousSchoolLevelGroupLabel: 'Primaire',
        validatedPreviousYear: false,
      );

      expect(
        result,
        const TargetSchoolLevelResolution(
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-3',
        ),
      );
    });

    test(
      'libellé de niveau absent (null) → défaut premier niveau du premier cycle',
      () {
        final result = resolveTargetSchoolLevel(
          schoolLevelGroups: groups,
          previousSchoolLevelLabel: null,
          previousSchoolLevelGroupLabel: null,
          validatedPreviousYear: true,
        );

        expect(
          result,
          const TargetSchoolLevelResolution(
            schoolLevelGroupId: 'grp-1',
            schoolLevelId: 'lvl-1',
          ),
        );
      },
    );

    test('libellé de niveau vide → défaut premier niveau du premier cycle', () {
      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: groups,
        previousSchoolLevelLabel: '',
        previousSchoolLevelGroupLabel: 'Primaire',
        validatedPreviousYear: false,
      );

      expect(
        result,
        const TargetSchoolLevelResolution(
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-1',
        ),
      );
    });

    test(
      'libellé de niveau introuvable dans le référentiel courant → défaut',
      () {
        final result = resolveTargetSchoolLevel(
          schoolLevelGroups: groups,
          previousSchoolLevelLabel: 'Niveau disparu',
          previousSchoolLevelGroupLabel: 'Primaire',
          validatedPreviousYear: true,
        );

        expect(
          result,
          const TargetSchoolLevelResolution(
            schoolLevelGroupId: 'grp-1',
            schoolLevelId: 'lvl-1',
          ),
        );
      },
    );

    test('libellé de groupe introuvable → recherche du niveau élargie à '
        'tous les cycles', () {
      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: groups,
        previousSchoolLevelLabel: '1ère Secondaire',
        previousSchoolLevelGroupLabel: 'Cycle disparu',
        validatedPreviousYear: true,
      );

      expect(
        result,
        const TargetSchoolLevelResolution(
          schoolLevelGroupId: 'grp-2',
          schoolLevelId: 'lvl-5',
        ),
      );
    });

    test(
      'libellé de groupe absent (null) → recherche du niveau dans tous les cycles',
      () {
        final result = resolveTargetSchoolLevel(
          schoolLevelGroups: groups,
          previousSchoolLevelLabel: '1ère Secondaire',
          previousSchoolLevelGroupLabel: null,
          validatedPreviousYear: true,
        );

        expect(
          result,
          const TargetSchoolLevelResolution(
            schoolLevelGroupId: 'grp-2',
            schoolLevelId: 'lvl-5',
          ),
        );
      },
    );

    test(
      'groupes triés dans le désordre → l\'ordre effectif reste par displayOrder',
      () {
        final unordered = [groups[1], groups[0]];

        final result = resolveTargetSchoolLevel(
          schoolLevelGroups: unordered,
          previousSchoolLevelLabel: '3ème Primaire',
          previousSchoolLevelGroupLabel: 'Primaire',
          validatedPreviousYear: true,
        );

        expect(
          result,
          const TargetSchoolLevelResolution(
            schoolLevelGroupId: 'grp-2',
            schoolLevelId: 'lvl-4',
          ),
        );
      },
    );

    test(
      'cycle suivant sans niveaux est ignoré, on saute au cycle d\'après',
      () {
        final withEmptyGroup = [
          groups[0],
          SchoolLevelGroupBundle(
            group: _group('grp-vide', 'Vide', 2),
            levels: const [],
          ),
          SchoolLevelGroupBundle(
            group: _group('grp-2', 'Secondaire', 3),
            levels: [_level('lvl-4', '1ère Secondaire', 1)],
          ),
        ];

        final result = resolveTargetSchoolLevel(
          schoolLevelGroups: withEmptyGroup,
          previousSchoolLevelLabel: '3ème Primaire',
          previousSchoolLevelGroupLabel: 'Primaire',
          validatedPreviousYear: true,
        );

        expect(
          result,
          const TargetSchoolLevelResolution(
            schoolLevelGroupId: 'grp-2',
            schoolLevelId: 'lvl-4',
          ),
        );
      },
    );

    test('référentiel totalement vide → null', () {
      final result = resolveTargetSchoolLevel(
        schoolLevelGroups: const [],
        previousSchoolLevelLabel: null,
        previousSchoolLevelGroupLabel: null,
        validatedPreviousYear: true,
      );

      expect(result, isNull);
    });
  });
}
