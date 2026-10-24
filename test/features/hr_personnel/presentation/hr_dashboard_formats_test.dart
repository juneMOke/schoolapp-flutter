import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_dashboard_page.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_sort_select.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../../../test_helpers/reference_formats.dart';
import '../hr_personnel_builders.dart';
import 'hr_personnel_harness.dart';

/// Le tableau de bord aux formats de référence (AGENTS.md §« Écran neuf ») :
/// indicateurs, répartition et « Qui sont-ils », avec des noms et des
/// fonctions longs, sans débordement — et le tri reste offert.
void main() {
  final file = snapshotOf([
    agent(
      'a',
      lastName: 'Kabasele-Tshimanga',
      middleName: 'Mwamba-Nkulu',
      firstName: 'Marie-Béatrice',
      sex: StaffSex.female,
      jobTitle: 'Professeure principale de mathématiques et de physique',
      branches: const ['Mathématiques', 'Physique', 'Chimie'],
      entryDate: '2009-09-01',
      contracts: [period(StaffContractKind.vacataire)],
    ),
    agent('b', lastName: 'Mayala', firstName: 'Ruth', sex: null),
    agent(
      'c',
      lastName: 'Élongo',
      firstName: 'Béatrice',
      category: StaffCategory.support,
      jobTitle: 'Agente d’entretien',
      staffNumber: null,
      entryDate: null,
    ),
  ]);

  testAtReferenceFormats('Tableau de bord RH', (tester, format) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrDashboardScreen(),
      size: null,
    );
    await tester.ensureVisible(find.byType(HrSortSelect));
    expect(find.byType(HrSortSelect), findsOneWidget);
  });
}
