import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_columns.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_grid_layout.dart';

CoteCours _cours(String id) =>
    CoteCours(coursId: id, branche: id, maxJournalier: 10, maxExamen: 20);

CoteColumn _column(String id, CoteColumnKind kind, {String periodeId = 'S1'}) =>
    CoteColumn(
      id: id,
      kind: kind,
      periodeId: periodeId,
      numero: 1,
      locked: false,
      sousPeriodeCount: 2,
    );

/// La suite d'une liste de lignes : `D`/`B` un titre, `c` un cours, `S` un
/// sous-total.
String _shape(List<CoteGridRow> rows) => rows
    .map(
      (row) => switch (row) {
        final CoteRubriqueRow r => r.isDomain ? 'D' : 'B',
        CoteCourseRow() => 'c',
        CoteSubtotalRow() => 'S',
      },
    )
    .join();

void main() {
  group('coteGridRows', () {
    test('une branche de plusieurs cours se referme sur un sous-total', () {
      final rows = coteGridRows([
        CoteRubrique(
          id: 'd',
          label: 'Domaine',
          sousRubriques: [
            CoteRubrique(
              id: 'b',
              label: 'Français',
              cours: [_cours('a'), _cours('b')],
            ),
          ],
        ),
      ]);
      expect(_shape(rows), 'DBccS');
      final subtotal = rows.last as CoteSubtotalRow;
      expect(subtotal.rubrique.id, 'b');
    });

    test('un cours seul n\'a jamais de sous-total, même demandé', () {
      final rows = coteGridRows([
        CoteRubrique(
          id: 'b',
          label: 'Sciences',
          produitSousTotal: true,
          cours: [_cours('a')],
        ),
      ]);
      expect(_shape(rows), 'Dc');
    });

    test('un domaine sans branche se referme comme une branche', () {
      final rows = coteGridRows([
        CoteRubrique(
          id: 'd',
          label: 'Univers',
          cours: [_cours('a'), _cours('b')],
        ),
      ]);
      expect(_shape(rows), 'DccS');
    });

    test(
      'le barème peut demander le total d\'un domaine, après ses branches',
      () {
        final rows = coteGridRows([
          CoteRubrique(
            id: 'd',
            label: 'Sciences',
            produitSousTotal: true,
            sousRubriques: [
              CoteRubrique(
                id: 'b1',
                label: 'Maths',
                cours: [_cours('a'), _cours('b')],
              ),
              CoteRubrique(id: 'b2', label: 'Techno', cours: [_cours('c')]),
            ],
          ),
        ]);
        expect(_shape(rows), 'DBccSBcS');
        expect((rows.last as CoteSubtotalRow).rubrique.id, 'd');
      },
    );

    test('un domaine à branche unique ne répète pas son sous-total', () {
      final rows = coteGridRows([
        CoteRubrique(
          id: 'd',
          label: 'Arts',
          produitSousTotal: true,
          sousRubriques: [
            CoteRubrique(
              id: 'b',
              label: 'Dessin',
              cours: [_cours('a'), _cours('b')],
            ),
          ],
        ),
      ]);
      expect(_shape(rows), 'DBccS');
    });

    test('une grille plate reste sans titre ni sous-total', () {
      final rows = coteGridRows([
        CoteRubrique(id: 'n', cours: [_cours('a'), _cours('b')]),
      ]);
      expect(_shape(rows), 'cc');
    });
  });

  group('pliage', () {
    final rubriques = [
      CoteRubrique(
        id: 'd',
        label: 'Domaine',
        sousRubriques: [
          CoteRubrique(
            id: 'b',
            label: 'Branche',
            cours: [_cours('a'), _cours('b')],
          ),
          CoteRubrique(id: 'c', label: 'Seule', cours: [_cours('c')]),
        ],
      ),
    ];

    test('une branche repliée garde son titre et sa somme', () {
      final rows = coteGridRows(rubriques, collapsed: {'b'});
      expect(_shape(rows), 'DBSBc');
      expect((rows[1] as CoteRubriqueRow).collapsed, isTrue);
    });

    test('un domaine replié cache ses branches, somme gardée', () {
      expect(_shape(coteGridRows(rubriques, collapsed: {'d'})), 'DS');
    });

    test('une branche d\'un seul cours repliée garde sa somme', () {
      expect(_shape(coteGridRows(rubriques, collapsed: {'c'})), 'DBccSBS');
    });

    test('les lignes d\'une rubrique sont teintées une sur deux', () {
      final rows = coteGridRows(rubriques).whereType<CoteCourseRow>().toList();
      expect(rows.map((r) => r.shaded), [false, true, false]);
    });
  });

  group('coteScoreInk', () {
    test('rouge sous la moitié, vert dès la moitié', () {
      expect(coteScoreInk(999, 2000), AppColors.error);
      expect(coteScoreInk(1000, 2000), AppColors.vertSavane);
      expect(coteScoreInk(2000, 2000), AppColors.vertSavane);
    });

    test('un arrondi ne fait pas basculer 49,6 % au vert', () {
      expect(coteScoreInk(992, 2000), AppColors.error);
    });

    test('rien de rempli : rien à juger', () {
      expect(coteScoreInk(0, 0), isNull);
    });
  });

  group('coteScoreMark', () {
    test('souligné sous la moitié, au même seuil que l\'encre', () {
      expect(coteScoreMark(999, 2000), TextDecoration.underline);
      expect(coteScoreMark(1000, 2000), TextDecoration.none);
    });

    test('rien de rempli : aucune marque', () {
      expect(coteScoreMark(0, 0), TextDecoration.none);
    });
  });

  group('coteGridColumns', () {
    String shape(List<CoteColumn> columns) => coteGridColumns(
      columns,
    ).map((c) => c.isMax ? 'M' : c.source.id).join(' ');

    test('un seul maximum devant les périodes d\'un groupe', () {
      expect(
        shape([
          _column('P1', CoteColumnKind.periode),
          _column('P2', CoteColumnKind.periode),
          _column('EX', CoteColumnKind.examen),
        ]),
        'M P1 P2 M EX',
      );
    });

    test('chaque groupe de l\'année a ses maxima, total compris', () {
      expect(
        shape([
          _column('P1', CoteColumnKind.periode),
          _column('EX1', CoteColumnKind.examen),
          _column('T1', CoteColumnKind.totalGroupe),
          _column('P2', CoteColumnKind.periode, periodeId: 'S2'),
        ]),
        'M P1 M EX1 M T1 M P2',
      );
    });

    test('une portée d\'une colonne garde son maximum', () {
      expect(shape([_column('P2', CoteColumnKind.periode)]), 'M P2');
    });
  });

  group('CoteGridMetrics', () {
    final columns = [
      _column('P1', CoteColumnKind.periode),
      _column('P2', CoteColumnKind.periode),
      _column('EX', CoteColumnKind.examen),
    ];

    test('le surplus de largeur va aux noms de cours, jusqu\'au plafond', () {
      final wide = CoteGridMetrics.of(1900, columns);
      expect(wide.courseWidth, AppDimensions.coteCourseColumnMax);
      final tight = CoteGridMetrics.of(700, columns);
      expect(tight.courseWidth, AppDimensions.coteCourseColumnDense);
    });

    test('le téléphone tient une colonne et son maximum sans défiler', () {
      final metrics = CoteGridMetrics.of(326, [
        _column('P1', CoteColumnKind.periode),
      ]);
      expect(metrics.minGridWidth, lessThanOrEqualTo(326));
    });
  });
}
