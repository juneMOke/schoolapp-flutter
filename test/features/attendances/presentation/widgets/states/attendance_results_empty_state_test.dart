import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_empty_state.dart';
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

  testWidgets('affiche le message et renvoie vers la Composition', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      host(AttendanceResultsEmptyState(onOpenComposition: () => opened = true)),
    );

    expect(find.text('Aucun élève dans cette classe'), findsOneWidget);
    expect(find.text('Ouvrir la Composition'), findsOneWidget);

    await tester.tap(find.text('Ouvrir la Composition'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('sans callback : aucune action affichee', (tester) async {
    await tester.pumpWidget(host(const AttendanceResultsEmptyState()));

    expect(find.text('Aucun élève dans cette classe'), findsOneWidget);
    expect(find.text('Ouvrir la Composition'), findsNothing);
  });
}
