import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/components/capture/document_capture_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  DocumentCaptureMode? picked;
  var closed = false;

  Future<void> openSheet(
    WidgetTester tester, {
    bool cameraUnavailable = false,
  }) async {
    picked = null;
    closed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showDocumentCaptureSheet(
                  context,
                  title: "Pièce d'identité",
                  cameraUnavailable: cameraUnavailable,
                  policy: DocumentCapturePolicy.staffDocument,
                );
                closed = true;
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('nomme la pièce, rappelle les bornes et propose trois gestes', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text("Pièce d'identité"), findsOneWidget);
    expect(find.text('JPEG, PNG ou PDF · 5 Mo au plus'), findsOneWidget);
    expect(find.text('Numériser'), findsOneWidget);
    expect(find.text('Importer une photo'), findsOneWidget);
    expect(find.text('Importer un PDF'), findsOneWidget);
  });

  testWidgets('un tap referme la feuille en rendant le geste', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Importer un PDF'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(picked, DocumentCaptureMode.importPdf);
    expect(find.text('Importer un PDF'), findsNothing);
  });

  testWidgets('sans caméra, Numériser disparaît au profit du message', (
    tester,
  ) async {
    await openSheet(tester, cameraUnavailable: true);

    expect(find.text('Numériser'), findsNothing);
    expect(
      find.text(
        "La caméra n'est pas disponible sur cette tablette. "
        'Importez un fichier à la place.',
      ),
      findsOneWidget,
    );
    expect(find.text('Importer une photo'), findsOneWidget);
    expect(find.text('Importer un PDF'), findsOneWidget);
  });

  testWidgets('refermer la feuille sans choisir rend null', (tester) async {
    await openSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(picked, isNull);
  });
}
