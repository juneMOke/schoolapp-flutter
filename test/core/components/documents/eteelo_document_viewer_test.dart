import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tailles réelles de la cible : tablette Android paysage, puis un téléphone
/// bas de gamme en paysage — les deux hauteurs où la modale est la plus serrée.
const _tabletLandscape = Size(1280, 800);
const _phoneLandscape = Size(720, 360);

final _document = PrintableDocument(
  bytes: Uint8List.fromList(const <int>[1, 2, 3]),
  fileName: 'registre-inscrits.pdf',
  reference: 'Du 01/09 au 30/09',
);

/// Monte la visionneuse avec un aperçu **de substitution**.
///
/// `EteeloPdfPreview` rasterise par canal de plateforme et ne se monte pas en
/// test widget : c'est exactement ce que le point d'injection existe pour
/// contourner. Tout ce qui est vérifié ici — en-tête, pied, gestes — vit autour
/// de l'aperçu, jamais dedans.
///
/// ⚠️ Le vrai thème est monté : un test qui prétend prémunir d'un débordement
/// sur tablette et monterait un `MaterialApp` nu ne verrait aucun défaut de
/// thème, alors que c'est sa raison d'être.
Future<void> _pumpViewer(
  WidgetTester tester, {
  Future<void> Function()? onPrint,
  bool canShare = true,
  PrintableDocument? document,
  Size size = _tabletLandscape,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EteeloDocumentViewerView(
          title: 'Registre des inscrits',
          document: document ?? _document,
          onPrint: onPrint,
          canShare: canShare,
          previewBuilder: (_, doc) => Text('aperçu de ${doc.fileName}'),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('en-tête', () {
    testWidgets('porte le titre et la référence du document', (tester) async {
      await _pumpViewer(tester);

      expect(find.text('Registre des inscrits'), findsOneWidget);
      expect(find.text('Du 01/09 au 30/09'), findsOneWidget);
      expect(find.text('aperçu de registre-inscrits.pdf'), findsOneWidget);
    });

    testWidgets('sans référence, la ligne ne s affiche pas vide', (
      tester,
    ) async {
      await _pumpViewer(
        tester,
        document: PrintableDocument(
          bytes: Uint8List.fromList(const <int>[1]),
          fileName: 'ticket.pdf',
        ),
      );

      expect(find.text('Registre des inscrits'), findsOneWidget);
      expect(find.text('Du 01/09 au 30/09'), findsNothing);
    });
  });

  group('pied d actions', () {
    testWidgets('propose imprimer, partager et fermer', (tester) async {
      await _pumpViewer(tester);

      expect(find.text('Imprimer'), findsOneWidget);
      expect(find.text('Partager'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });

    // Le partage dépose la pièce EN CLAIR dans le cache de l'application
    // jusqu'à la fin de session : un appelant doit pouvoir le refuser.
    testWidgets('canShare faux retire le partage, et lui seul', (tester) async {
      await _pumpViewer(tester, canShare: false);

      expect(find.text('Partager'), findsNothing);
      expect(find.text('Imprimer'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });
  });

  group('geste d impression', () {
    // La clé de voûte : les tickets passent leur propre flux (thermique
    // d'abord, PDF en filet) là où un rapport part au spouleur.
    testWidgets('l action fournie remplace la remise au spouleur', (
      tester,
    ) async {
      var called = 0;
      await _pumpViewer(tester, onPrint: () async => called++);

      await tester.tap(find.text('Imprimer'));
      await tester.pump();

      expect(called, 1);
      expect(tester.takeException(), isNull);
    });

    // Sans cette prise en charge, l'appui ne produirait RIEN : ni papier, ni
    // message, et l'exception partirait en erreur asynchrone non capturée.
    testWidgets('un geste qui échoue se dit, il ne se tait pas', (
      tester,
    ) async {
      await _pumpViewer(tester, onPrint: () async => throw Exception('canal'));

      await tester.tap(find.text('Imprimer'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text("L'action n'a pas pu aboutir sur cet appareil."),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ouverture et fermeture', () {
    testWidgets('fermer referme la visionneuse', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                // ⚠️ L'aperçu de substitution est indispensable ICI aussi : le
                // vrai gabarit de chargement est un shimmer perpétuel, et
                // `pumpAndSettle` ne rendrait jamais la main.
                onPressed: () => showEteeloDocumentViewer(
                  context,
                  title: 'Rapport de caisse',
                  document: _document,
                  onPrint: () async {},
                  previewBuilder: (_, doc) => Text('aperçu de ${doc.fileName}'),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Rapport de caisse'), findsOneWidget);

      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.text('Rapport de caisse'), findsNothing);
    });
  });

  // Régression connue du socle : la modale est plafonnée à 88 % de la hauteur
  // d'écran, en-tête et pied pris dessus. Sur un écran très bas, il restait
  // moins que la hauteur demandée par le corps.
  testWidgets('aucun débordement sur un écran très bas', (tester) async {
    await _pumpViewer(tester, size: _phoneLandscape);

    expect(tester.takeException(), isNull);
  });
}
