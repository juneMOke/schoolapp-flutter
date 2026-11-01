import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_columns.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

const _fr = CoteCours(
  coursId: 'fr',
  branche: 'Français',
  maxJournalier: 20,
  maxExamen: 40,
);
const _eps = CoteCours(
  coursId: 'eps',
  branche: 'EPS',
  maxJournalier: 10,
  maxExamen: 0,
);

const _classe = CoteClasse(
  classroomId: 'c',
  decoupage: Decoupage.semestre,
  periodes: [
    CotePeriode(
      id: 'S1',
      ordre: 1,
      libelle: 'Semestre 1',
      courant: true,
      locked: false,
      sousPeriodes: [
        CoteSousPeriode(id: 'P1', ordre: 1, locked: false),
        CoteSousPeriode(id: 'P2', ordre: 2, locked: false),
      ],
    ),
  ],
  rubriques: [
    CoteRubrique(id: 'r', cours: [_fr, _eps]),
  ],
  eleves: [],
);

CoteCell _cell(
  String col, {
  String student = 'e',
  String cours = 'fr',
  double? cote,
  double? calculee,
  String? invalid,
  SyncState state = SyncState.synced,
}) => CoteCell(
  key: CoteCellKey(
    studentId: student,
    coursId: cours,
    colonneId: col,
    examen: col == 'S1',
  ),
  serverCote: cote,
  calculee: calculee,
  invalidRaw: invalid,
  syncState: state,
  hasDraft: state == SyncState.syncError,
  draftValue: state == SyncState.syncError ? cote : null,
);

void main() {
  const calculator = CoteCalculator();
  final columns = columnsFor(_classe, defaultScope(_classe));

  CoteEleveCalc calc(
    List<CoteCell> cells, {
    List<CoteCours> cours = const [_fr],
  }) => calculator.calcEleve(
    studentId: 'e',
    cours: cours,
    columns: columns,
    cells: CoteCellTable.of(cells),
  );

  group('calcul d\'un élève', () {
    test('Total S1 = P1 + P2 + examen', () {
      final result = calc([
        _cell('P1', cote: 14),
        _cell('P2', cote: 16),
        _cell('S1', cote: 31),
      ]);
      expect(result.total, 6100);
      expect(result.maxScope, 8000);
      expect(result.pct, 76);
      expect(result.complete, isTrue);
      expect(result.provisoire, isFalse);
    });

    test('provisoire : le pourcentage porte sur les maxima remplis', () {
      final result = calc([_cell('P1', cote: 14), _cell('P2', cote: 16)]);
      expect(result.total, 3000);
      expect(result.maxFilled, 4000);
      expect(result.maxScope, 8000);
      expect(result.pct, 75);
      expect(result.provisoire, isTrue);
    });

    test('une frappe hors barème sort des totaux et compte à corriger', () {
      final result = calc([
        _cell('P1', cote: 14),
        _cell('P2', invalid: '24'),
        _cell('S1', cote: 31),
      ]);
      expect(result.total, 4500);
      expect(result.maxFilled, 6000);
      expect(result.pct, 75);
      expect(result.invalid, 1);
      expect(result.complete, isFalse);
    });

    test('une cote refusée reste à corriger et ne compte pas', () {
      final result = calc([
        _cell('P1', cote: 14),
        _cell('P2', cote: 15, state: SyncState.syncError),
      ]);
      expect(result.total, 1400);
      expect(result.invalid, 1);
    });

    test('une valeur calculée compte comme remplie, 0 compris', () {
      final result = calc([
        _cell('P1', calculee: 13.25),
        _cell('P2', calculee: 0),
      ]);
      expect(result.filled, 2);
      expect(result.total, 1325);
      expect(result.maxFilled, 4000);
    });

    test('une cote prime sur la valeur calculée', () {
      expect(calc([_cell('P1', cote: 18, calculee: 12)]).total, 1800);
    });

    test('un cours sans examen ne compte ni la cellule ni son maximum', () {
      final result = calc(
        [
          _cell('P1', cours: 'eps', cote: 7),
          _cell('P2', cours: 'eps', cote: 6),
        ],
        cours: const [_eps],
      );
      expect(result.cells, 2);
      expect(result.maxScope, 2000);
      expect(result.complete, isTrue);
    });

    test('sans rien de rempli, pas de pourcentage', () {
      expect(calc(const []).pct, isNull);
    });

    test('le maximum d\'un groupe suit le nombre réel de sous-périodes', () {
      final total = yearColumns(_classe).firstWhere((c) => !c.isInput);
      expect(total.maxFor(_fr), 80);
      expect(total.maxFor(_eps), 20);
      expect(calculator.columnMax(const [_fr, _eps], total), 100);
    });

    test('la somme d\'un total de groupe additionne ses colonnes', () {
      final year = yearColumns(_classe);
      final sum = calculator.columnSum(
        studentId: 'e',
        cours: const [_fr],
        column: year.firstWhere((c) => !c.isInput),
        year: year,
        cells: CoteCellTable.of([
          _cell('P1', cote: 14),
          _cell('P2', cote: 16.5),
          _cell('S1', cote: 31),
        ]),
      );
      expect(sum, 6150);
    });
  });

  group('rang', () {
    CoteEleveCalc pct(int total, int max) => CoteEleveCalc(
      total: total,
      maxFilled: max,
      maxScope: max,
      filled: 1,
      cells: 1,
      invalid: 0,
      cours: const {},
    );

    test('ex æquo : 1, 2, 2, 4', () {
      final ranking = calculator.rank({
        'a': pct(80, 100),
        'b': pct(70, 100),
        'c': pct(70, 100),
        'd': pct(60, 100),
      });
      expect(ranking.rangs, {'a': 1, 'b': 2, 'c': 2, 'd': 4});
      expect(ranking.classes, 4);
    });

    test('compare à 2 décimales, comme le bulletin', () {
      // 74,301 % et 74,304 % : mêmes 74,30 %, donc ex æquo au bulletin.
      final ranking = calculator.rank({
        'a': pct(74301, 100000),
        'b': pct(74304, 100000),
        'c': pct(74310, 100000),
      });
      expect(ranking.rangs, {'c': 1, 'a': 2, 'b': 2});
    });

    test('un pourcentage arrondi égal mais des décimales différentes', () {
      final ranking = calculator.rank({
        'a': pct(7440, 10000),
        'b': pct(7430, 10000),
      });
      expect(ranking.rangs, {'a': 1, 'b': 2});
    });

    test('.5 s\'arrondit vers le haut', () {
      expect(roundedPercent(1, 8), 13);
      expect(pct(1, 8).pctHundredths, 1250);
    });

    test('un élève sans note n\'est pas classé', () {
      final ranking = calculator.rank({
        'a': pct(80, 100),
        'b': const CoteEleveCalc(
          total: 0,
          maxFilled: 0,
          maxScope: 100,
          filled: 0,
          cells: 1,
          invalid: 0,
          cours: {},
        ),
      });
      expect(ranking.rangs, {'a': 1});
      expect(ranking.classes, 1);
    });

    test('un zéro saisi classe l\'élève', () {
      final ranking = calculator.rank({'a': pct(0, 100)});
      expect(ranking.rangs, {'a': 1});
    });
  });

  test('progression : remplies, attendues, complets', () {
    final progress = calculator.progress([
      const CoteEleveCalc(
        total: 1,
        maxFilled: 1,
        maxScope: 1,
        filled: 3,
        cells: 3,
        invalid: 0,
        cours: {},
      ),
      const CoteEleveCalc(
        total: 1,
        maxFilled: 1,
        maxScope: 1,
        filled: 1,
        cells: 3,
        invalid: 0,
        cours: {},
      ),
    ]);
    expect(progress.filled, 4);
    expect(progress.cells, 6);
    expect(progress.complets, 1);
  });
}
