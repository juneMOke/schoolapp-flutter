import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/states/schedule_results_empty_state.dart';
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
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('variante semaine : « Aucune séance planifiée »', (tester) async {
    await tester.pumpWidget(host(const ScheduleResultsEmptyState()));

    expect(find.text('Aucune séance planifiée.'), findsOneWidget);
    expect(find.textContaining('direction des études'), findsOneWidget);
  });

  testWidgets('variante jour : titre + jour sélectionné', (tester) async {
    await tester.pumpWidget(
      host(const ScheduleResultsEmptyState(day: Weekday.wed)),
    );

    expect(find.text('Aucun cours ce jour'), findsOneWidget);
    expect(find.textContaining('Mercredi'), findsOneWidget);
  });
}
