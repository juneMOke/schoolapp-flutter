import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_app_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, {required bool hasBalance}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        appBar: FacturationDetailAppBar(
          fullName: 'Kabongo Mwamba Daniel',
          eyebrow: 'Facturation · 6e A',
          firstName: 'Daniel',
          lastName: 'Kabongo',
          fallbackRoute: '/finances/facturations',
          trailing: FacturationBalancePill(
            hasBalance: hasBalance,
            label: hasBalance ? '150 USD dû' : 'À jour',
          ),
        ),
        child: const SizedBox(height: 200),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AppBar facturation : sur-titre MAJ, titre, initiales, retour/fermer, pastille « dû »',
    (tester) async {
      await _pump(tester, hasBalance: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Sur-titre or-doux en MAJUSCULES.
      expect(find.text('FACTURATION · 6E A'), findsOneWidget);
      // Titre = nom complet.
      expect(find.text('Kabongo Mwamba Daniel'), findsOneWidget);
      // Avatar à initiales (Nom + Prénom).
      expect(find.text('KD'), findsOneWidget);
      // Boutons retour + fermer.
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      // Pastille de solde dû.
      expect(find.text('150 USD dû'), findsOneWidget);
      expect(
        find.byIcon(Icons.account_balance_wallet_outlined),
        findsOneWidget,
      );
    },
  );

  testWidgets('pastille « à jour » quand le solde est nul', (tester) async {
    await _pump(tester, hasBalance: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('À jour'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
