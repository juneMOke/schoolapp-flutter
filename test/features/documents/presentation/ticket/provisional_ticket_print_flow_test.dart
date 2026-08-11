import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// Même raison que dans `provisional_ticket_printer_test` : le paquet n'exporte
// pas son interface de plateforme, alors que c'est le point de substitution
// prévu. Sans elle, le repli lèverait `MissingPluginException` sur la VM hôte,
// et « le filet s'est bien déployé » ne serait pas vérifiable.
// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _netum = ThermalPrinter(
  name: 'NT-8003DD',
  macAddress: 'DC:0D:30:11:22:33',
);

/// L'enchaînement des deux sorties, tel que le guichet le vit.
///
/// Ce fichier n'épingle qu'une chose, mais c'est la décision de fond du lot :
/// **la thermique d'abord, la cause dite, le PDF en filet — et rien du tout
/// quand le caissier renonce.** Le repli est ce qui garantit qu'un parent qui a
/// versé des espèces repart avec un papier ; l'annonce est ce qui évite qu'on
/// aille chercher la panne du côté de l'imprimante quand c'est une permission
/// qui manque.
void main() {
  late _FakePrinting printing;
  late _FakePort port;
  late _FakePermission permission;
  late _FakeTicketRepository repository;

  setUp(() {
    printing = _FakePrinting();
    PrintingPlatform.instance = printing;
    port = _FakePort();
    permission = _FakePermission();
    repository = _FakeTicketRepository();
    getIt
      ..registerSingleton<ThermalPrinterPort>(port)
      ..registerSingleton<ThermalPrinterPermission>(permission)
      ..registerFactory<BuildProvisionalTicketUseCase>(
        () => BuildProvisionalTicketUseCase(repository),
      );
  });

  tearDown(getIt.reset);

  /// Lance le flux, et joue le choix de l'imprimante s'il est proposé.
  Future<void> run(WidgetTester tester, {String? choose = 'NT-8003DD'}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => printProvisionalTicketWithFallback(
                context,
                paymentId: 'pay-1',
                messenger: ScaffoldMessenger.maybeOf(context),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text(choose ?? 'Annuler'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('thermique servie : ni message, ni spouleur', (tester) async {
    await run(tester);

    expect(port.sentTo, equals([_netum.macAddress]));
    // Le filet ne se déploie pas quand le trapèze a tenu : ouvrir le spouleur
    // ici sortirait un SECOND papier pour le même versement.
    expect(printing.laidOut, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('caissier qui renonce : rien, et surtout pas le PDF', (
    tester,
  ) async {
    await run(tester, choose: null);

    expect(port.sentTo, isEmpty);
    // Insister en ouvrant le spouleur système sous les doigts de quelqu'un qui
    // vient d'appuyer sur Annuler serait faire ce qu'on lui refuse.
    expect(printing.laidOut, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Bluetooth éteint : la cause est dite, PUIS le PDF sort', (
    tester,
  ) async {
    port.readyProblem = ThermalPrinterProblem.bluetoothOff;

    await run(tester);

    expect(
      find.text('Bluetooth éteint — impression PDF à la place.'),
      findsOne,
    );
    expect(printing.laidOut, isNotEmpty);
  });

  testWidgets('aucune imprimante appairée : cause propre, pas « injoignable »', (
    tester,
  ) async {
    port.printers = const [];

    await run(tester);

    // La nuance compte au guichet : « aucune appairée » s'adresse à qui met en
    // service la tablette, « injoignable » à qui rallume la machine.
    expect(
      find.text('Aucune imprimante appairée — impression PDF à la place.'),
      findsOne,
    );
    expect(printing.laidOut, isNotEmpty);
  });

  testWidgets('les deux sorties rendent le MÊME ticket', (tester) async {
    port.sendProblem = ThermalPrinterProblem.unreachable;

    await run(tester);

    // Le repli reçoit le modèle déjà composé : une seule lecture du versement,
    // donc aucune fenêtre pour qu'une écriture concurrente fasse diverger le
    // papier remis au parent de celui que la thermique n'a pas pu sortir.
    expect(repository.builds, 1);
    expect(printing.laidOut, isNotEmpty);
  });

  testWidgets('versement introuvable : dit, et rien d\'imprimé', (
    tester,
  ) async {
    repository.result = const Left(NotFoundFailure('introuvable'));

    await run(tester);

    expect(
      find.text(
        'Impression indisponible : le ticket n\'a pas pu être produit.',
      ),
      findsOne,
    );
    expect(printing.laidOut, isEmpty);
    expect(port.sentTo, isEmpty);
  });
}

class _FakePort implements ThermalPrinterPort {
  ThermalPrinterProblem? readyProblem;
  ThermalPrinterProblem? sendProblem;
  List<ThermalPrinter> printers = const [_netum];
  final List<String> sentTo = [];

  @override
  Future<Either<Failure, Unit>> ensureReady() async {
    final problem = readyProblem;
    return problem == null
        ? const Right(unit)
        : Left(ThermalPrinterFailure(problem));
  }

  @override
  Future<Either<Failure, List<ThermalPrinter>>> pairedPrinters() async {
    final problem = readyProblem;
    return problem == null
        ? Right(printers)
        : Left(ThermalPrinterFailure(problem));
  }

  @override
  Future<Either<Failure, Unit>> printBytes(
    Uint8List bytes, {
    required String macAddress,
  }) async {
    final problem = sendProblem;
    if (problem != null) return Left(ThermalPrinterFailure(problem));
    sentTo.add(macAddress);
    return const Right(unit);
  }
}

class _FakePermission implements ThermalPrinterPermission {
  @override
  Future<bool> isGranted() async => true;

  @override
  Future<ThermalPrinterPermissionState> request() async =>
      ThermalPrinterPermissionState.granted;

  @override
  Future<void> openSettings() async {}
}

class _FakeTicketRepository implements ProvisionalTicketRepository {
  Either<Failure, TicketReceiptModel>? result;
  int builds = 0;

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async {
    builds++;
    return result ?? Right(_model(labels));
  }
}

TicketReceiptModel _model(TicketLabels labels) => TicketReceiptModel(
  schoolName: 'Complexe scolaire La Colombe',
  studentFullName: 'Mbala Kasa Amina',
  provisionalReference: 'PROV-TAB1-0001',
  paidAt: DateTime(2026, 8, 12, 9, 30),
  amountReceivedInCents: 2500000,
  currency: 'CDF',
  labels: labels,
);

class _FakePrinting extends PrintingPlatform {
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
    laidOut.add(await onLayout(PdfPageFormat.a4));
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
