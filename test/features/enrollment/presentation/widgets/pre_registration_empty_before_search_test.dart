import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/pre_registration/pre_registration_empty_before_search.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHost(Widget child) {
    return MaterialApp(
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
  }

  testWidgets('affiche le titre et le message d invitation pré-inscription', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHost(const PreRegistrationEmptyBeforeSearch()),
    );

    expect(find.byIcon(Icons.manage_search_rounded), findsOneWidget);
    expect(
      find.text('Lancez une recherche de pré-inscription'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Remplissez le formulaire ci-dessus puis cliquez sur Rechercher pour afficher les demandes.',
      ),
      findsOneWidget,
    );
  });
}
