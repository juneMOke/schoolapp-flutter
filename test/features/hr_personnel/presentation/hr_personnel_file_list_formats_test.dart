import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_personnel_file_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/grid/staff_agent_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/list/staff_agent_table.dart';

import '../../../test_helpers/reference_formats.dart';
import '../hr_personnel_builders.dart';
import 'hr_personnel_harness.dart';

/// Le mode « Liste » du fichier du personnel aux formats de référence : sous
/// `dataTableCardsMax`, les cartes (le tableau de 760 dp défilait de côté à
/// 360) et le tri par nom au-dessus d'elles ; au-delà, le tableau.
void main() {
  final file = snapshotOf([
    agent('a', lastName: 'Kalala', firstName: 'Didier'),
    agent('b', lastName: 'Mayala', firstName: 'Ruth'),
    agent('c', lastName: 'Élongo', firstName: 'Béatrice'),
  ]);

  testAtReferenceFormats('la liste tient, le tri se garde', (
    tester,
    format,
  ) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrPersonnelFileScreen(),
      size: null,
    );
    await tester.tap(find.text('Liste'));
    await tester.pump();

    final table = find.byType(StaffAgentTable);
    final cards =
        tester.getSize(table).width < AppBreakpoints.dataTableCardsMax;
    expect(
      find.descendant(of: table, matching: find.byType(StaffAgentCard)),
      cards ? findsNWidgets(3) : findsNothing,
    );
    // Rien ne défile de côté dans la liste du téléphone.
    if (cards) {
      for (final element
          in find
              .descendant(of: table, matching: find.byType(Scrollable))
              .evaluate()) {
        final state = (element as StatefulElement).state as ScrollableState;
        expect(state.widget.axisDirection, isNot(AxisDirection.right));
      }
    }

    List<String> ids() => [
      for (final row in tester.widget<StaffAgentTable>(table).rows)
        row.member.id,
    ];
    expect(ids(), ['c', 'a', 'b']);
    final sort = find.text('AGENT');
    await tester.ensureVisible(sort);
    final target = find.ancestor(of: sort, matching: find.byType(InkWell));
    expect(
      tester.getSize(target.first).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    await tester.tap(sort);
    await tester.pump();
    expect(ids(), ['b', 'a', 'c']);
  });
}
