import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('Enrollment detail loading template uses localized labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(const EnrollmentDetailLoadingTemplate()),
    );

    expect(find.text('Chargement du dossier'), findsOneWidget);
    expect(
      find.text('Veuillez patienter pendant la récupération des informations.'),
      findsOneWidget,
    );
  });

  testWidgets('Enrollment detail error template exposes retry action', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      buildHarness(
        EnrollmentDetailErrorTemplate(
          message: 'Erreur réseau',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Impossible de charger le dossier'), findsOneWidget);
    expect(find.text('Erreur réseau'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
