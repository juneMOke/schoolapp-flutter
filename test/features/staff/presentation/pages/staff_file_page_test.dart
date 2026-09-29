import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_file_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  testWidgets("la page d'attente dit qu'il n'y a encore rien à montrer", (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StaffFilePage()),
      ),
    );

    expect(find.byType(EteeloEmptyResult), findsOneWidget);
    expect(
      find.text("Le fichier du personnel n'est pas encore disponible"),
      findsOneWidget,
    );
    expect(
      find.text(
        'Les fiches des agents apparaîtront ici dès que le serveur les '
        'enverra à cette tablette.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
