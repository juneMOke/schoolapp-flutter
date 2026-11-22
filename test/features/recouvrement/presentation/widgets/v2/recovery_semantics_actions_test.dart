import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_situation_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_controls.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_simulation_table.dart';

import 'simulation/simulation_test_harness.dart';

/// Un `Semantics(button: true, excludeSemantics: true)` sans `onTap` tait
/// l'action du bouton enfant : le lecteur d'écran annonce un bouton qui ne
/// fait rien. Chaque nœud porte ici l'action « toucher », et elle agit.
void main() {
  /// Le nœud dont le libellé commence par [prefix], son action « toucher »
  /// vérifiée puis déclenchée.
  void tapByLabel(WidgetTester tester, Pattern prefix) {
    final finder = find.bySemanticsLabel(prefix);
    expect(finder, findsOneWidget);
    final node = tester.getSemantics(finder);
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    node.owner!.performAction(node.id, SemanticsAction.tap);
  }

  testWidgets('B · une ligne de situation se touche au lecteur d\'écran', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final tapped = <StudentChargeStatus>[];
    await pumpSimulation(
      tester,
      RecoverySituationCard(
        counts: const RecoverySituationCounts(
          noPayment: 12,
          partial: 13,
          settled: 15,
        ),
        studentCount: 40,
        onSituationTapped: tapped.add,
      ),
    );
    tapByLabel(tester, RegExp(r'^Partiellement payé : 13 élèves'));
    await tester.pump();
    expect(tapped, [StudentChargeStatus.partial]);
    handle.dispose();
  });

  testWidgets('F · « Changer » se touche au lecteur d\'écran', (tester) async {
    final handle = tester.ensureSemantics();
    var changes = 0;
    await pumpSimulation(
      tester,
      RecoverySimulationControls(
        criterionLabel: "N'ont rien payé",
        unmanageableBelow: 60,
        onUnmanageableChanged: (_) {},
        onChangeRule: () => changes++,
      ),
    );
    tapByLabel(tester, RegExp(r'^Changer la règle'));
    await tester.pump();
    expect(changes, 1);
    handle.dispose();
  });

  testWidgets('F · une ligne du tableau s\'ouvre au lecteur d\'écran', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final opened = <RecoverySimulationRow>[];
    final rows = [
      simRow('c1', '1ère primaire', headcount: 30, targeted: 6),
      simRow('c2', '2ème primaire', headcount: 30, targeted: 0),
    ];
    await pumpSimulation(
      tester,
      RecoverySimulationTable(
        rows: rows,
        unmanageableBelow: 60,
        onClassTapped: opened.add,
      ),
    );
    tapByLabel(tester, RegExp(r'^1ère primaire : '));
    await tester.pump();
    expect(opened.single.classroomId, 'c1');
    // Sans élève visé, la ligne reste inerte : ni bouton, ni action.
    final idle = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^2ème primaire : ')),
    );
    expect(idle, isNot(isSemantics(hasTapAction: true)));
    handle.dispose();
  });
}
