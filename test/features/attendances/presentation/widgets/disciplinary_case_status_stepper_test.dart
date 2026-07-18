import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
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
        const DisciplinaryCaseStatusStepper(status: DisciplinaryStatus.pending),
      ),
    );

    expect(find.text('Ouvert'), findsOneWidget);
    expect(find.text('Pris en charge'), findsOneWidget);
    expect(find.text('Résolu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('classé sans suite : pastille terminale dédiée', (tester) async {
    await tester.pumpWidget(
      host(
        const DisciplinaryCaseStatusStepper(
          status: DisciplinaryStatus.dismissed,
        ),
      ),
    );

    expect(find.text('Classé sans suite'), findsOneWidget);
    // Hors du chemin linéaire : pas les étapes intermédiaires.
    expect(find.text('Pris en charge'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
