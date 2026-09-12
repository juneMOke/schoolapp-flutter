import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_ranking_projector.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_cycle_tree.dart';

SchoolLevel _level(String id, int order) => SchoolLevel(
  id: id,
  name: id,
  code: id,
  displayOrder: order,
  splitIntoClassrooms: false,
);

/// Deux cycles déclarés dans le DÉSORDRE, niveaux compris : l'arbre doit suivre
/// les rangs du référentiel, pas l'ordre des listes qui le transportent.
final _labels = FeeControlDashboardLabels.from([
  SchoolLevelGroupBundle(
    group: const SchoolLevelGroup(
      id: 'sec',
      name: 'Secondaire',
      code: 'SEC',
      displayOrder: 2,
    ),
    levels: [_level('s8', 2), _level('s7', 1)],
  ),
  SchoolLevelGroupBundle(
    group: const SchoolLevelGroup(
      id: 'prim',
      name: 'Primaire',
      code: 'PRIM',
      displayOrder: 1,
    ),
    levels: [_level('p2', 2), _level('p1', 1)],
  ),
]);

RecouvrementGroupRow _row(
  String? levelId, {
  int settled = 0,
  int partial = 0,
  int none = 0,
}) => RecouvrementGroupRow(
  schoolLevelId: levelId,
  breakdown: FeeControlBreakdown(
    settled: settled,
    partial: partial,
    none: none,
  ),
  remaining: MoneyBag.empty,
);

List<String?> _cycles(List<RecouvrementCycleNode> nodes) => [
  for (final node in nodes) node.cycleId,
];

List<String?> _levels(RecouvrementCycleNode node) => [
  for (final level in node.levels) level.schoolLevelId,
];

void main() {
  test('aucune ligne, aucun cycle', () {
    expect(RecouvrementCycleTree.build(const [], _labels), isEmpty);
  });

  test('chaque niveau sous son cycle, cycles et niveaux dans l\'ordre du '
      'référentiel — jamais dans celui du retard', () {
    // L'ordre du classement : le plus en retard d'abord.
    final nodes = RecouvrementCycleTree.build([
      _row('s8', none: 4),
      _row('p2', none: 3),
      _row('s7', partial: 2),
      _row('p1', settled: 5),
    ], _labels);

    expect(_cycles(nodes), ['prim', 'sec']);
    expect(_levels(nodes[0]), ['p1', 'p2']);
    expect(_levels(nodes[1]), ['s7', 's8']);
  });

  test('un cycle SOMME ses niveaux, sans rien recompter', () {
    final nodes = RecouvrementCycleTree.build([
      _row('p1', settled: 3, partial: 1),
      _row('p2', settled: 1, none: 2),
    ], _labels);

    expect(
      nodes.single.breakdown,
      const FeeControlBreakdown(settled: 4, partial: 1, none: 2),
    );
  });

  test('ce que le référentiel ne sait pas rattacher ferme la marche — le '
      'niveau inconnu avant la ligne sans niveau', () {
    final nodes = RecouvrementCycleTree.build([
      _row(null, none: 2),
      _row('inconnu-b', none: 1),
      _row('p1', settled: 1),
      _row('inconnu-a', partial: 1),
    ], _labels);

    expect(_cycles(nodes), ['prim', null]);
    expect(nodes.last.isUnplaced, isTrue);
    expect(_levels(nodes.last), ['inconnu-a', 'inconnu-b', null]);
  });

  test('rien ne se perd : le total des cycles est celui des niveaux', () {
    final groups = [
      _row('p1', settled: 3, partial: 1),
      _row('s7', none: 4),
      _row(null, none: 2),
      _row('inconnu', partial: 5),
    ];
    final nodes = RecouvrementCycleTree.build(groups, _labels);

    int sum(Iterable<FeeControlBreakdown> all) =>
        all.fold(0, (total, breakdown) => total + breakdown.total);
    expect(
      sum(nodes.map((node) => node.breakdown)),
      sum(groups.map((group) => group.breakdown)),
    );
    expect(nodes.expand((node) => node.levels).length, groups.length);
  });
}
