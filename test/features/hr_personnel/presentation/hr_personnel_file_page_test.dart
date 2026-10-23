import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_personnel_file_page.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/grid/staff_agent_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/list/staff_agent_table.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/stats/staff_stats_band.dart';

import '../hr_personnel_builders.dart';
import 'hr_personnel_harness.dart';

void main() {
  final file = snapshotOf([
    agent('a', lastName: 'Kalala', firstName: 'Didier'),
    agent('b', lastName: 'Mayala', firstName: 'Ruth'),
    agent(
      'c',
      lastName: 'Élongo',
      firstName: 'Béatrice',
      category: StaffCategory.administrative,
      jobTitle: 'Économe',
    ),
  ]);

  testWidgets('ni statistiques ni filtre par contrat', (tester) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrPersonnelFileScreen(),
    );

    expect(find.byType(StaffAgentCard), findsNWidgets(3));
    expect(find.byType(StaffStatsBand), findsNothing);
    expect(find.text('Dossier incomplet'), findsNothing);
    expect(find.text('3 agents au fichier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recherche et catégorie se combinent ; le pied dit « n sur N »', (
    tester,
  ) async {
    final cubit = await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrPersonnelFileScreen(),
    );

    await tester.enterText(find.byType(EditableText).first, 'a');
    await tester.pump();
    cubit.setCategory(HrCategoryKey.teacher);
    await tester.pump();

    expect(find.byType(StaffAgentCard), findsNWidgets(2));
    expect(find.text('2 agents sur 3'), findsOneWidget);
  });

  testWidgets('l\'en-tête « Agent » inverse l\'ordre de la liste', (
    tester,
  ) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrPersonnelFileScreen(),
    );
    await tester.tap(find.text('Liste'));
    await tester.pump();

    List<String> ids() => [
      for (final row
          in tester.widget<StaffAgentTable>(find.byType(StaffAgentTable)).rows)
        row.member.id,
    ];
    expect(ids(), ['c', 'a', 'b']);

    await tester.tap(find.text('AGENT'));
    await tester.pump();
    expect(ids(), ['b', 'a', 'c']);
  });

  testWidgets('un fichier vide propose le premier agent', (tester) async {
    await pumpHrScreen(
      tester,
      snapshot: snapshotOf(const []),
      screen: const HrPersonnelFileScreen(),
    );

    expect(find.text('Aucun agent dans le fichier'), findsOneWidget);
  });
}
