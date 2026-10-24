import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/pages/hr_personnel_file_page.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_sort_select.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

import '../../../test_helpers/reference_formats.dart';
import '../hr_personnel_builders.dart';
import 'hr_personnel_harness.dart';

/// Le Fichier aux formats de référence (AGENTS.md §« Écran neuf ») : cartes
/// puis liste, avec des noms et des fonctions longs, sans débordement — et le
/// tri reste offert quel que soit l'affichage.
void main() {
  final file = snapshotOf([
    agent(
      'a',
      lastName: 'Kabasele-Tshimanga',
      middleName: 'Mwamba-Nkulu',
      firstName: 'Marie-Béatrice',
      jobTitle: 'Professeure principale de mathématiques et de physique',
      branches: const ['Mathématiques', 'Physique', 'Chimie'],
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

  testAtReferenceFormats('Fichier du personnel', (tester, format) async {
    await pumpHrScreen(
      tester,
      snapshot: file,
      screen: const HrPersonnelFileScreen(),
      size: null,
    );
    expect(find.byType(HrSortSelect), findsOneWidget);

    await tester.ensureVisible(find.text('Liste'));
    await tester.tap(find.text('Liste'));
    await tester.pump();
    expect(find.byType(HrSortSelect), findsOneWidget);
  });
}
