import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_cycle_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  testWidgets('affiche un etat vide quand la distribution cycle est vide', (
    tester,
  ) async {
    const distribution = CycleDistribution(cycles: []);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: EnrollmentStatsCycleSection(distribution: distribution),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Aucune donnée pour cette période'), findsOneWidget);
  });
}
