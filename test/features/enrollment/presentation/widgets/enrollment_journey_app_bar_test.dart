import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_app_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHost(PreferredSizeWidget appBar) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(appBar: appBar),
    );
  }

  testWidgets('affiche le mode, le nom eleve et le compteur d etape', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHost(
        const EnrollmentJourneyAppBar(
          modeLabel: 'Nouvelle',
          studentDisplayName: 'Jean Doe',
          currentStep: 2,
          totalSteps: 7,
        ),
      ),
    );

    expect(find.text('NOUVELLE'), findsOneWidget);
    expect(find.text('Jean Doe'), findsOneWidget);
    expect(find.text('Étape 3 / 7'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
