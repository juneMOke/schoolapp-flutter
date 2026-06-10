import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_invitation_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: FacturationSearchInvitationCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('utilise le composant DS unifié avec la copie facturation', (
    tester,
  ) async {
    await pump(tester);

    // Design unifié (composant partagé) + icône facturation contextuelle.
    expect(find.byType(SearchInvitationCard), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.text('Aucune recherche en cours'), findsOneWidget);
    expect(
      find.text(
        'Saisissez un nom ou un niveau ci-dessus pour afficher les élèves correspondants.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
