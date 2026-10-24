import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';

import '../../../test_helpers/reference_formats.dart';
import '../hr_presence_builders.dart';
import 'hr_presence_dashboard_harness.dart';

/// Le tableau de bord aux formats de référence (AGENTS.md §« Écran neuf ») :
/// les alertes posées, un mois entier de barres et des noms longs, sans
/// débordement.
void main() {
  final month = [
    for (var day = 1; day <= 23; day++)
      if (DateTime(2026, 10, day).weekday <= DateTime.friday)
        barOf(
          '2026-10-${day.toString().padLeft(2, '0')}',
          rate: day == 23 ? null : 70 + day,
        ),
  ];
  final dashboard = dashboardOf(
    kpis: kpisOf(unscored: 6, lateMinutes: 1412),
    series: month,
    staff: [
      staffRow(
        'a',
        lastName: 'KABASELE-TSHIMANGA',
        firstName: 'Marie-Béatrice',
        jobTitle: 'Professeure principale de mathématiques et de physique',
        kpis: kpisOf(rate: 62, late: 14, lateMinutes: 412, unjustified: 9),
      ),
      staffRow('b', lastName: 'MAYALA', firstName: 'Ruth'),
      staffRow(
        'c',
        lastName: 'ÉLONGO',
        firstName: 'Béatrice',
        kpis: kpisOf(rate: null),
      ),
    ],
  );

  testAtReferenceFormats('Tableau de bord des présences', (
    tester,
    format,
  ) async {
    await pumpHrPresenceDashboard(
      tester,
      server: FakeHrAttendanceStats(dashboard),
      unsynced: 3,
      size: null,
    );
    expect(find.text('Assiduité par agent'), findsOneWidget);
  });

  testAtReferenceFormats('Tableau de bord sur l\'année, mois par mois', (
    tester,
    format,
  ) async {
    await pumpHrPresenceDashboard(
      tester,
      server: FakeHrAttendanceStats(
        dashboardOf(
          granularity: HrAttendanceGranularity.month,
          series: [
            for (var m = 9; m <= 12; m++)
              barOf('2026-${m.toString().padLeft(2, '0')}'),
            for (var m = 1; m <= 6; m++) barOf('2027-0$m'),
          ],
        ),
      ),
      size: null,
    );
    expect(find.text('Présence mois par mois'), findsOneWidget);
  });
}
