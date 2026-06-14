import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_status_stepper.dart';
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

  testWidgets('affiche les 3 étapes du cycle', (tester) async {
    await tester.pumpWidget(
      host(
        const DisciplinaryCaseStatusStepper(
          status: DisciplinaryCaseStatus.inProgress,
        ),
      ),
    );

    expect(find.text('Ouvert'), findsOneWidget);
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Clôturé'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
