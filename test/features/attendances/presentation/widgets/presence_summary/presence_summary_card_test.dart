import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_attendance_summary.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_card.dart';
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
    home: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 760, child: child)),
    ),
  );

  final summary = StudentAttendanceSummary(
    studentId: 's',
    firstName: 'J',
    lastName: 'D',
    academicYearName: '2025-2026',
    period: StatsPeriod.year,
    windowStart: DateTime(2025, 9, 1),
    windowEnd: DateTime(2026, 6, 30),
    presenceRate: 91,
    presentDays: 78,
    justifiedAbsenceDays: 5,
    unjustifiedAbsenceDays: 3,
    absences: const [],
  );

  testWidgets('rend l en-tete, les 4 KPI et le sous-titre de repartition', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PresenceSummaryCard(
          data: PresenceSummaryViewData(summary),
          rangeLabel: 'Année scolaire 2025-2026',
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Synthèse de présence'), findsOneWidget);

    // Cartes KPI (4) : libelles + valeurs.
    expect(find.text('Taux de présence'), findsOneWidget);
    expect(find.text('91 %'), findsOneWidget);
    expect(find.text('Présent'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('Absence justifiée'), findsOneWidget);
    expect(find.text('Absence injustifiée'), findsOneWidget);

    // Sous-titre de la barre : present (78) sur total (86).
    expect(find.text('78 jours présents sur 86'), findsOneWidget);

    // En-tete : plage + nombre de jours scolaires.
    expect(find.textContaining('Année scolaire 2025-2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
