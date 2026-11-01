import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// Même raison que dans `provisional_ticket_print_flow_test` : le paquet
// n'exporte pas son interface de plateforme, le point de substitution prévu.
// ignore: implementation_imports
import 'package:printing/src/interface.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/cancellation_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_cancellation_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/cancellation_ticket_print_flow.dart';
import 'package:school_app_flutter/features/school/data/school_logo_band_loader.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _netum = ThermalPrinter(
  name: 'NT-8003DD',
  macAddress: 'DC:0D:30:11:22:33',
);

const _labels = TicketCancellationLabels(
  title: 'TICKET D\'ANNULATION',
  receiptLabel: 'Reçu n°',
  cancelledMark: 'ANNULÉ',
  issuedAtLabel: 'Émis le',
  amountLabel: 'Montant :',
  cancelledAtLabel: 'Annulé le',
  reasonLabel: 'Motif :',
  detailLabel: 'Précision :',
  cashReturnedLabel: 'Argent rendu :',
  yes: 'Oui',
  no: 'Non',
  cancelledByLabel: 'Par :',
  classroomLabel: 'Classe :',
  schoolPhoneLabel: 'Tél. Promoteur :',
  tillPhoneLabel: 'Tél. caisse :',
  verificationNotice: 'Scannez pour vérifier ce reçu',
  reasons: {'REFUNDED': 'Argent rendu au payeur'},
);

/// Le ticket d'annulation suit le geste du ticket de caisse : l'aperçu d'abord,
/// et rien ne part tant que personne n'a appuyé sur « Imprimer ».
void main() {
  late _FakePrinting printing;
  late _FakePort port;
  late _FakeQueue queue;
  late _FakeTickets tickets;

  setUp(() {
    printing = _FakePrinting();
    PrintingPlatform.instance = printing;
    port = _FakePort();
    queue = _FakeQueue();
    tickets = _FakeTickets();
    getIt
      ..registerSingleton<ThermalPrinterPort>(port)
      ..registerSingleton<ThermalPrinterPermission>(_FakePermission())
      ..registerFactory<BuildCancellationTicketUseCase>(
        () => BuildCancellationTicketUseCase(tickets),
      )
      ..registerFactory<MarkCancellationTicketPrintedUseCase>(
        () => MarkCancellationTicketPrintedUseCase(queue),
      )
      ..registerSingleton<CurrentUserContext>(
        CurrentUserContext()..set('u-1', schoolId: 'ecole-1'),
      )
      ..registerSingleton<SchoolLogoBandLoader>(_FakeBandLoader())
      ..registerFactory<ResolveTicketCopiesUseCase>(
        () => ResolveTicketCopiesUseCase(_FakeSchools()),
      );
  });

  tearDown(getIt.reset);

  Future<bool?> open(WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await printCancellationTicket(
                  context,
                  paymentId: 'pay-1',
                  messenger: ScaffoldMessenger.maybeOf(context),
                  previewBuilder: (_, _) => const SizedBox.shrink(),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('l aperçu s ouvre, et rien ne part sans appui', (tester) async {
    await open(tester);

    expect(find.text('Imprimer'), findsOneWidget);
    expect(port.sentTo, isEmpty);
    expect(printing.laidOut, isZero);
    expect(queue.marked, isZero);
  });

  testWidgets('tablette : Imprimer sort la thermique et solde la file', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.text('Imprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NT-8003DD'));
    await tester.pumpAndSettle();

    expect(port.sentTo, [_netum.macAddress]);
    expect(printing.laidOut, isZero);
    expect(queue.marked, 1);
    expect(find.text('Imprimer'), findsNothing);
  });

  testWidgets(
    'poste : Imprimer passe par le spouleur, sans solder la file',
    (tester) async {
      await open(tester);

      await tester.tap(find.text('Imprimer'));
      await tester.pumpAndSettle();

      expect(printing.laidOut, 1);
      expect(port.sentTo, isEmpty);
      expect(queue.marked, isZero);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.linux,
    }),
  );

  testWidgets('sans nom d élève, aucun aperçu', (tester) async {
    tickets.studentFullName = '';

    await open(tester);

    expect(find.text('Imprimer'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

class _FakeTickets implements CancellationTicketRepository {
  String studentFullName = 'Mbala Kasa Amina';

  @override
  Future<Either<Failure, TicketCancellationModel>> buildForPayment({
    required String paymentId,
    required TicketCancellationLabels labels,
  }) async => Right(
    TicketCancellationModel(
      schoolName: 'Collège La Fontaine',
      receiptNumber: 'CF-RC-2627-000821',
      originalPaidAt: DateTime(2026, 10, 5, 12, 43),
      studentFullName: studentFullName,
      classroomName: '5e A',
      amount: MoneyBag.of(const [Money(15000, 'USD')]),
      cancelledAt: DateTime(2026, 10, 6, 9, 12),
      reason: 'Argent rendu au payeur',
      cashMoved: true,
      labels: _labels,
    ),
  );
}

class _FakeQueue implements TicketPrintQueueRepository {
  int marked = 0;

  @override
  Future<Either<Failure, Unit>> markCancellationPrinted(
    String paymentId,
  ) async {
    marked++;
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePort implements ThermalPrinterPort {
  final List<String> sentTo = [];

  @override
  Future<Either<Failure, Unit>> ensureReady() async => const Right(unit);

  @override
  Future<Either<Failure, List<ThermalPrinter>>> pairedPrinters() async =>
      const Right([_netum]);

  @override
  Future<Either<Failure, Unit>> printBytes(
    Uint8List bytes, {
    required String macAddress,
    int copies = 1,
  }) async {
    sentTo.add(macAddress);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

class _FakePrinting extends PrintingPlatform {
  int laidOut = 0;

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
    await onLayout(PdfPageFormat.a4);
    laidOut++;
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

class _FakeBandLoader implements SchoolLogoBandLoader {
  @override
  Future<TicketLogoBand?> thermalBand(String? schoolId) async => null;
}

class _FakeSchools implements SchoolRepository {
  @override
  Future<Either<Failure, School?>> loadCurrentSchool() async =>
      const Right(School(id: 'ecole-1', name: 'EP Kimbanguiste'));

  @override
  Future<Either<Failure, SchoolLogo?>> loadCurrentSchoolLogo() async =>
      const Right(null);
}
