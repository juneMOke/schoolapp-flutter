import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// Le paquet n'exporte pas son interface de plateforme, alors que c'est le point
// de substitution prévu (`PrintingPlatform.instance`) et celui qu'utilise sa
// propre suite. Sans elle, `layoutPdf` lève `MissingPluginException` sur la VM
// hôte et le chemin nominal — celui qui compose pour le média annoncé — resterait
// entièrement non testé.
// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/ticket/ticket_block_geometry.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_printer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le repli d'impression compose le ticket **pour le média que le spouleur
/// annonce**, dans `onLayout`. Tout s'y joue : le format n'est plus imposé, il
/// est reçu — et un rendu qui lèverait à cet endroit annulerait toute la tâche
/// d'impression, là où le rendu était auparavant fait AVANT l'appel plateforme
/// et donc attrapable.
void main() {
  late _FakePrinting printing;
  late _FakeTicketRepository repository;

  setUp(() {
    printing = _FakePrinting();
    PrintingPlatform.instance = printing;
    repository = _FakeTicketRepository();
    if (getIt.isRegistered<BuildProvisionalTicketUseCase>()) {
      getIt.unregister<BuildProvisionalTicketUseCase>();
    }
    getIt.registerFactory<BuildProvisionalTicketUseCase>(
      () => BuildProvisionalTicketUseCase(repository),
    );
  });

  tearDown(() => getIt.unregister<BuildProvisionalTicketUseCase>());

  testWidgets('compose pour le média annoncé, pas pour le format proposé', (
    tester,
  ) async {
    // Le spouleur annonce une thermique 80 mm, marges minimales nulles : c'est
    // ce média-là que le ticket doit épouser, pas l'A4 de la proposition.
    const announced = PdfPageFormat(
      80 * PdfPageFormat.mm,
      200 * PdfPageFormat.mm,
    );
    printing.announce = announced;

    final printed = await _print(tester);

    expect(printed, isTrue);
    expect(printing.proposedFormat, PdfPageFormat.a4);
    expect(printing.laidOut, isNotEmpty);
    // Preuve que le rendu a bien suivi le média : sur la laize du ticket, aucun
    // cadre de découpe n'est tracé — il n'y a pas de papier à retirer.
    expect(TicketBlockGeometry.hasPaperToCut(announced), isFalse);
    expect(_dashPatterns(printing.laidOut.last), 0);
  });

  testWidgets('une feuille de bureau reçoit bien le cadre de découpe', (
    tester,
  ) async {
    printing.announce = PdfPageFormat.a4;

    await _print(tester);

    expect(_dashPatterns(printing.laidOut.last), 2);
  });

  // Un média que le bloc ne peut pas honorer ne doit pas emporter la tâche
  // entière : le repli est le filet, il ne casse pas à son tour.
  testWidgets('un média impossible retombe sur le rendu de référence', (
    tester,
  ) async {
    printing.announce = const PdfPageFormat(80 * PdfPageFormat.mm, 1);

    final printed = await _print(tester);

    expect(printed, isTrue);
    // La signature du repli : c'est la page A4 de référence qui est remise, pas
    // un rendu sur le média impossible. Sans cette assertion le test passerait
    // aussi si le rendu avait réussi — et ne prouverait donc rien.
    expect(
      String.fromCharCodes(printing.laidOut.last),
      contains('MediaBox[0 0 595.27559 841.88976]'),
    );
  });

  testWidgets('un service d\'impression absent est DIT, jamais avalé', (
    tester,
  ) async {
    printing.failure = MissingPluginException('pas de canal');

    expect(await _print(tester), isFalse);
  });

  testWidgets('un encaissement introuvable n\'imprime rien', (tester) async {
    repository.result = const Left(NotFoundFailure('introuvable'));

    expect(await _print(tester), isFalse);
    expect(printing.laidOut, isEmpty);
  });
}

Future<bool> _print(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return printProvisionalTicket(captured, paymentId: 'pay-1');
}

/// Occurrences du motif de pointillés — le marqueur des deux horizontales de
/// découpe dans le flux de contenu.
int _dashPatterns(Uint8List bytes) =>
    '[3 3] 0 d'.allMatches(_inflate(bytes)).length;

String _inflate(Uint8List bytes) {
  final raw = String.fromCharCodes(bytes);
  final buffer = StringBuffer();
  var index = raw.indexOf('stream');

  while (index >= 0) {
    final end = raw.indexOf('endstream', index);
    if (end < 0) break;
    var start = index + 'stream'.length;
    while (start < end && _isEol(raw.codeUnitAt(start))) {
      start++;
    }
    var stop = end;
    while (stop > start && _isEol(raw.codeUnitAt(stop - 1))) {
      stop--;
    }
    try {
      buffer.write(
        String.fromCharCodes(zlib.decode(bytes.sublist(start, stop).toList())),
      );
    } catch (_) {
      // Flux non déflaté : sans intérêt ici.
    }
    index = raw.indexOf('stream', end + 'endstream'.length);
  }

  return buffer.toString();
}

bool _isEol(int code) => code == 13 || code == 10;

class _FakeTicketRepository implements ProvisionalTicketRepository {
  Either<Failure, TicketReceiptModel>? result;

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async => result ?? Right(_model(labels));
}

TicketReceiptModel _model(TicketLabels labels) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  studentFullName: 'Mbala Kasa Amina',
  provisionalReference: 'PROV-A1B2C3',
  paidAt: DateTime(2026, 8, 4, 14, 7),
  amountReceivedInCents: 150000,
  currency: 'CDF',
  labels: labels,
);

/// Spouleur de test : rejoue le contrat réel du plugin — `onLayout` est rappelé
/// avec le média **sélectionné**, jamais avec le format proposé.
class _FakePrinting extends PrintingPlatform {
  PdfPageFormat announce = PdfPageFormat.a4;
  PdfPageFormat? proposedFormat;
  Object? failure;
  final List<Uint8List> laidOut = [];

  @override
  Future<bool> layoutPdf(
    Printer? printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
    bool dynamicLayout,
    bool usePrinterSettings,
    OutputType outputType,
    bool forceCustomPrintPaper,
  ) async {
    proposedFormat = format;
    if (failure != null) throw failure!;
    laidOut.add(await onLayout(announce));
    return true;
  }

  @override
  Future<PrintingInfo> info() async => throw UnimplementedError();

  @override
  Future<List<Printer>> listPrinters() => throw UnimplementedError();

  @override
  Future<Printer?> pickPrinter(Rect bounds) => throw UnimplementedError();

  @override
  Future<bool> sharePdf(
    Uint8List bytes,
    String filename,
    Rect bounds,
    String? subject,
    String? body,
    List<String>? emails,
  ) => throw UnimplementedError();

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) => throw UnimplementedError();

  @override
  Stream<PdfRaster> raster(Uint8List document, List<int>? pages, double dpi) =>
      throw UnimplementedError();
}
