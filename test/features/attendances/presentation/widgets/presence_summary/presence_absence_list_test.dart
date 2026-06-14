import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_absence_list.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  PresenceSummaryViewData buildVm() => PresenceSummaryViewData(
    StudentAttendanceSummary(
      studentId: 's',
      firstName: 'J',
      lastName: 'D',
      academicYearName: '2025-2026',
      period: StatsPeriod.year,
      windowStart: DateTime(2025, 9, 1),
      windowEnd: DateTime(2026, 6, 30),
      presenceRate: 90,
      presentDays: 80,
      justifiedAbsenceDays: 1,
      unjustifiedAbsenceDays: 1,
      absences: [
        StudentAbsenceEntry(
          date: DateTime(2026, 1, 14),
          reason: AbsenceReason.unjustified,
          reasonNote: 'Sans motif',
        ),
        StudentAbsenceEntry(
          date: DateTime(2026, 1, 9),
          reason: AbsenceReason.sickness,
        ),
      ],
    ),
  );

  testWidgets('fermee par defaut puis depliable avec pastilles de statut', (
    tester,
  ) async {
    await tester.pumpWidget(host(PresenceAbsenceList(data: buildVm())));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Détail des absences'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // badge de comptage

    // Fermee : aucune pastille visible.
    expect(find.text('Absence injustifiée'), findsNothing);
    expect(find.text('Absence justifiée'), findsNothing);

    await tester.tap(find.text('Détail des absences'));
    await tester.pumpAndSettle();

    // Ouverte : une pastille par statut, mappee depuis le motif.
    expect(find.text('Absence injustifiée'), findsOneWidget);
    expect(find.text('Absence justifiée'), findsOneWidget);
    expect(find.text('Sans motif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
