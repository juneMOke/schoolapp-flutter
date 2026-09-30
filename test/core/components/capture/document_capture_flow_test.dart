import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/document_digest.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/capture/document_capture_service.dart';
import 'package:school_app_flutter/core/components/capture/document_capture_flow.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../capture/capture_fixtures.dart';

/// Feuille simulée : rend les gestes prévus, dans l'ordre, et note si la
/// caméra lui a été annoncée indisponible.
class _ScriptedSheet {
  final List<DocumentCaptureMode?> answers;
  final List<bool> cameraUnavailableSeen = [];

  _ScriptedSheet(this.answers);

  Future<DocumentCaptureMode?> open(
    BuildContext context, {
    required String title,
    bool cameraUnavailable = false,
  }) async {
    cameraUnavailableSeen.add(cameraUnavailable);
    return answers.removeAt(0);
  }
}

void main() {
  late FakeDocumentCaptureGateway gateway;
  CapturedDocument? captured;

  Future<void> runFlow(WidgetTester tester, _ScriptedSheet sheet) async {
    captured = null;
    final flow = DocumentCaptureFlow(
      DocumentCaptureService(gateway, digest: digestDocument),
      openSheet: sheet.open,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await flow.run(context, title: 'Diplôme');
              },
              child: const Text('capturer'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('capturer'));
    await tester.pumpAndSettle();
  }

  setUp(() => gateway = FakeDocumentCaptureGateway());

  testWidgets('rend la pièce obtenue', (tester) async {
    gateway.next = RawCapture(bytes: pdfBytes, fileName: 'diplome.pdf');

    await runFlow(tester, _ScriptedSheet([DocumentCaptureMode.importPdf]));

    expect(captured?.mimeType, DocumentMimeType.pdf);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    "une caméra refusée rouvre la feuille sans Numériser : jamais d'impasse",
    (tester) async {
      gateway = _CameraRefusedOnceGateway(jpegBytes);
      final sheet = _ScriptedSheet([
        DocumentCaptureMode.scan,
        DocumentCaptureMode.importImage,
      ]);

      await runFlow(tester, sheet);

      expect(sheet.cameraUnavailableSeen, [false, true]);
      expect(captured?.mimeType, DocumentMimeType.jpeg);
    },
  );

  testWidgets('une pièce trop lourde est annoncée, et rien ne revient', (
    tester,
  ) async {
    gateway.next = RawCapture(
      bytes: Uint8List(DocumentCapturePolicy.maxBytes + 1)..setAll(0, pdfBytes),
    );

    await runFlow(tester, _ScriptedSheet([DocumentCaptureMode.importPdf]));

    expect(captured, isNull);
    expect(
      find.text('Ce fichier dépasse 5 Mo. Choisissez-en un plus léger.'),
      findsOneWidget,
    );
  });

  testWidgets('renoncer ne dit rien', (tester) async {
    await runFlow(tester, _ScriptedSheet([null]));

    expect(captured, isNull);
    expect(find.byType(SnackBar), findsNothing);
    expect(gateway.calls, isEmpty);
  });
}

/// Refuse la caméra au premier appel, puis rend [bytes].
class _CameraRefusedOnceGateway extends FakeDocumentCaptureGateway {
  final Uint8List bytes;
  var _first = true;

  _CameraRefusedOnceGateway(this.bytes);

  @override
  Future<RawCapture?> acquire(DocumentCaptureMode mode) async {
    calls.add(mode);
    if (_first) {
      _first = false;
      throw const CameraUnavailableException();
    }
    return RawCapture(bytes: bytes);
  }
}
