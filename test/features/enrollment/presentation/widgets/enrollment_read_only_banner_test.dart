import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_read_only_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau de consultation annonce un dossier « non modifiable ». Dès que
/// l'en-tête propose « Modifier », cette phrase devient fausse — et c'est le
/// genre de contradiction qu'un écran porte longtemps sans que personne ne la
/// signale.
void main() {
  Future<void> ouvrir(WidgetTester tester, {required bool offert}) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: EnrollmentReadOnlyBanner(correctionOffered: offert),
        ),
      ),
    );
  }

  testWidgets('sans correction proposée : le dossier est dit non modifiable', (
    tester,
  ) async {
    await ouvrir(tester, offert: false);

    expect(find.textContaining('non modifiable'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('correction proposée : plus de « non modifiable », et le bandeau '
      'dit ce que l\'enregistrement fera', (tester) async {
    await ouvrir(tester, offert: true);

    expect(find.textContaining('non modifiable'), findsNothing);
    expect(find.textContaining('corriger'), findsOneWidget);
    expect(find.textContaining('file d\'envoi'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
  });
}
