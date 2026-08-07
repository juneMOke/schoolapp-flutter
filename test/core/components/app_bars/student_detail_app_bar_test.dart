import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  Widget? trailing,
  bool showCloseButton = false,
  String firstName = 'Daniel',
  String lastName = 'Kabongo',
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppPageBackground(
        appBar: StudentDetailAppBar(
          fullName: 'Kabongo Mwamba Daniel',
          eyebrow: 'Facturation · 6e A',
          firstName: firstName,
          lastName: lastName,
          fallbackRoute: '/finances/facturations',
          showCloseButton: showCloseButton,
          trailing: trailing,
        ),
        child: const SizedBox(height: 200),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sur-titre MAJ, titre, initiales et retour', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Sur-titre or-doux en MAJUSCULES.
    expect(find.text('FACTURATION · 6E A'), findsOneWidget);
    // Titre = nom complet.
    expect(find.text('Kabongo Mwamba Daniel'), findsOneWidget);
    // Avatar à initiales (Nom + Prénom).
    expect(find.text('KD'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('la croix de fermeture n apparaît que si demandée', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await _pump(tester, showCloseButton: true);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('replie sur « ? » quand l identité est inconnue', (tester) async {
    await _pump(tester, firstName: '   ', lastName: '');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('pose la pastille de synthèse fournie par le module', (
    tester,
  ) async {
    await _pump(
      tester,
      trailing: const StudentDetailAppBarPill(
        accent: AppColors.error,
        icon: Icons.error_outline,
        label: '2 cas ouverts',
        alert: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('2 cas ouverts'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
