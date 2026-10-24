import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_sort_select.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../../../test_helpers/reference_formats.dart';
import 'hr_dashboard_harness.dart';

/// Le tableau de bord aux formats de référence (AGENTS.md §« Écran neuf ») :
/// indicateurs, répartition et « Qui sont-ils », avec des noms et des
/// fonctions longs, sans débordement — et le tri reste offert.
void main() {
  final rows = [
    serverRow(
      'a',
      lastName: 'KABASELE-TSHIMANGA',
      middleName: 'Mwamba-Nkulu',
      firstName: 'Marie-Béatrice',
      sex: StaffSex.female,
      jobTitle: 'Professeure principale de mathématiques et de physique',
      entryDate: '2009-09-01',
      seniorityYears: 17,
      contractKind: StaffContractKind.vacataire,
      dossier: const HrDossierCount(provided: 2, required: 4),
    ),
    serverRow('b', lastName: 'MAYALA', firstName: 'Ruth', sex: null),
    serverRow(
      'c',
      lastName: 'ÉLONGO',
      firstName: 'Béatrice',
      category: HrCategoryKey.support,
      jobTitle: 'Agente d’entretien',
      entryDate: null,
      seniorityYears: null,
      contractKind: null,
    ),
  ];

  testAtReferenceFormats('Tableau de bord RH', (tester, format) async {
    await pumpHrDashboard(
      tester,
      server: FakeHrStaffDashboard(rows),
      size: null,
    );
    await tester.ensureVisible(find.byType(HrSortSelect));
    expect(find.byType(HrSortSelect), findsOneWidget);
  });
}
