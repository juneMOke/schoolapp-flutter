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
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/cancellation_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/ticket_print_queue_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_cancellation_model.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_cancellation_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_printer_picker.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/ticket_batch_print_flow.dart';
import 'package:school_app_flutter/features/school/data/school_logo_band_loader.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _printer = ThermalPrintChoice(
  printer: ThermalPrinter(name: 'NT-8003DD', macAddress: 'DC:0D:30:11:22:33'),
  copies: 2,
);

TicketPrintJob _job(
  String id, {
  TicketPrintJobKind kind = TicketPrintJobKind.receipt,
}) => TicketPrintJob(
  id: id,
  paymentId: 'p-$id',
  kind: kind,
  state: TicketPrintJobState.ready,
  receiptNumber: 'CF-RC-2627-00080$id',
  studentFullName: 'Mbala Kasa Amina',
  amount: MoneyBag.of(const [Money(15000, 'USD')]),
  enteredAt: DateTime.utc(2026, 10, 12),
);

/// L'impression d'un lot de « Tickets à imprimer » (continuité des tickets RC,
/// lot D) : une imprimante pour tout le lot, chaque ticket marqué dès que SON
/// envoi a réussi, et la première panne qui arrête tout.
void main() {
  late _Queue queue;
  late _Receipts receipts;
  late _Cancellations cancellations;
  late List<String> sent;
  late List<int> askedCopies;

  setUp(() {
    queue = _Queue();
    receipts = _Receipts();
    cancellations = _Cancellations();
    sent = [];
    askedCopies = [];
    getIt
      ..registerSingleton<CurrentUserContext>(
        CurrentUserContext()..set('u-1', schoolId: 'ecole-1'),
      )
      ..registerSingleton<SchoolLogoBandLoader>(_NoBand())
      ..registerFactory<ResolveTicketCopiesUseCase>(
        () => ResolveTicketCopiesUseCase(_Schools()),
      )
      ..registerFactory<BuildProvisionalTicketUseCase>(
        () => BuildProvisionalTicketUseCase(receipts),
      )
      ..registerFactory<BuildCancellationTicketUseCase>(
        () => BuildCancellationTicketUseCase(cancellations),
      )
      ..registerFactory<MarkTicketJobPrintedUseCase>(
        () => MarkTicketJobPrintedUseCase(queue),
      )
      ..registerFactory<RecordTicketJobProblemUseCase>(
        () => RecordTicketJobProblemUseCase(queue),
      );
  });

  tearDown(getIt.reset);

  Future<BuildContext> contextOf(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return context;
  }

  Future<Either<ThermalTicketOutcome, ThermalPrintChoice>> choosePrinter(
    BuildContext _, {
    int initialCopies = 1,
  }) async {
    askedCopies.add(initialCopies);
    return const Right(_printer);
  }

  ThermalBytesSender sender({String? failsOn}) {
    var index = 0;
    return (bytes, choice) async {
      final id = '${++index}';
      if (id == failsOn) return ThermalPrinterProblem.unreachable;
      sent.add(id);
      return null;
    };
  }

  testWidgets('une imprimante pour le lot, chaque ticket marqué imprimé', (
    tester,
  ) async {
    final context = await contextOf(tester);

    final outcome = await printTicketBatch(
      context,
      jobs: [
        _job('1'),
        _job('2', kind: TicketPrintJobKind.cancellation),
        _job('3'),
      ],
      choose: choosePrinter,
      send: sender(),
    );

    expect(outcome.printed, 3);
    expect(outcome.problem, isNull);
    // Une seule question, avec le nombre d'exemplaires de l'école.
    expect(askedCopies, [3]);
    expect(sent, ['1', '2', '3']);
    expect(queue.printed, ['1', '2', '3']);
  });

  testWidgets('la première panne arrête le lot, la suite reste en file', (
    tester,
  ) async {
    final context = await contextOf(tester);

    final outcome = await printTicketBatch(
      context,
      jobs: [_job('1'), _job('2'), _job('3')],
      choose: choosePrinter,
      send: sender(failsOn: '2'),
    );

    expect(outcome.printed, 1);
    expect(outcome.problem, ThermalPrinterProblem.unreachable);
    expect(queue.printed, ['1']);
    expect(queue.problems, {'2': 'unreachable'});
  });

  testWidgets('un ticket qui ne nomme personne est écarté, pas envoyé', (
    tester,
  ) async {
    final context = await contextOf(tester);
    receipts.anonymous.add('p-2');

    final outcome = await printTicketBatch(
      context,
      jobs: [_job('1'), _job('2'), _job('3')],
      choose: choosePrinter,
      send: (bytes, choice) async {
        sent.add('envoi');
        return null;
      },
    );

    expect(outcome.printed, 2);
    expect(outcome.skipped, 1);
    expect(sent, hasLength(2));
    expect(queue.printed, ['1', '3']);
  });

  testWidgets('choix refermé : rien ne part, rien n est marqué', (
    tester,
  ) async {
    final context = await contextOf(tester);

    final outcome = await printTicketBatch(
      context,
      jobs: [_job('1')],
      choose: (_, {initialCopies = 1}) async =>
          const Left(ThermalTicketCancelled()),
      send: sender(),
    );

    expect(outcome.cancelled, isTrue);
    expect(outcome.problem, isNull);
    expect(sent, isEmpty);
    expect(queue.printed, isEmpty);
  });

  testWidgets('imprimante injoignable avant tout envoi : la cause est dite', (
    tester,
  ) async {
    final context = await contextOf(tester);

    final outcome = await printTicketBatch(
      context,
      jobs: [_job('1')],
      choose: (_, {initialCopies = 1}) async => const Left(
        ThermalTicketFailed(ThermalPrinterProblem.noPrinterSelected),
      ),
      send: sender(),
    );

    expect(outcome.cancelled, isFalse);
    expect(outcome.problem, ThermalPrinterProblem.noPrinterSelected);
    expect(sent, isEmpty);
  });

  // Le bouton de la page : le même cheminement que tout autre ticket.
  group('aperçu puis impression', () {
    late _FakePrinting printing;

    setUp(() {
      printing = _FakePrinting();
      PrintingPlatform.instance = printing;
    });

    TicketBatchOutcome? outcome;

    Future<void> open(
      WidgetTester tester, {
      List<TicketPrintJob>? jobs,
      ThermalBytesSender? send,
    }) async {
      outcome = null;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  outcome = await reviewAndPrintTicketBatch(
                    context,
                    jobs:
                        jobs ??
                        [
                          _job('1'),
                          _job('2', kind: TicketPrintJobKind.cancellation),
                        ],
                    choose: choosePrinter,
                    send: send ?? sender(),
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
    }

    testWidgets('l aperçu s ouvre, et le refermer ne sort rien', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Imprimer'), findsOneWidget);
      expect(sent, isEmpty);

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();

      expect(outcome?.cancelled, isTrue);
      expect(sent, isEmpty);
      expect(queue.printed, isEmpty);
    });

    testWidgets('tablette : Imprimer sort le lot et solde la file', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Imprimer'));
      await tester.pumpAndSettle();

      expect(outcome?.printed, 2);
      expect(sent, ['1', '2']);
      expect(queue.printed, ['1', '2']);
    });

    const desktop = TargetPlatformVariant({
      TargetPlatform.windows,
      TargetPlatform.linux,
    });

    testWidgets('poste : le spouleur, puis le caissier dit si c est sorti', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Imprimer'));
      await tester.pumpAndSettle();

      expect(printing.laidOut, 1);
      expect(sent, isEmpty);
      expect(queue.printed, isEmpty);

      await tester.tap(find.text('Oui, retirer de la liste'));
      await tester.pumpAndSettle();

      expect(outcome?.printed, 2);
      expect(queue.printed, ['1', '2']);
    }, variant: desktop);

    testWidgets('poste : sans confirmation, les tickets restent en file', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('Imprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Non, les garder'));
      await tester.pumpAndSettle();

      expect(outcome?.printed, 0);
      expect(queue.printed, isEmpty);
    }, variant: desktop);

    testWidgets('poste : un spouleur indisponible se dit', (tester) async {
      printing.fails = true;
      await open(tester);

      await tester.tap(find.text('Imprimer'));
      await tester.pumpAndSettle();

      expect(outcome?.spoolerFailed, isTrue);
      expect(queue.printed, isEmpty);
    }, variant: desktop);

    testWidgets('rien d imprimable : aucun aperçu vide', (tester) async {
      receipts.anonymous.add('p-1');

      await open(tester, jobs: [_job('1')]);

      expect(find.text('Imprimer'), findsNothing);
      expect(outcome?.skipped, 1);
    });
  });
}

class _Queue implements TicketPrintQueueRepository {
  final List<String> printed = [];
  final Map<String, String> problems = {};

  @override
  Future<Either<Failure, Unit>> markPrinted(TicketPrintJob job) async {
    printed.add(job.id);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> recordProblem(
    TicketPrintJob job,
    String problem,
  ) async {
    problems[job.id] = problem;
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Receipts implements ProvisionalTicketRepository {
  /// Versements dont l'élève n'est pas sur ce poste.
  final Set<String> anonymous = {};

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async => Right(
    TicketReceiptModel(
      schoolName: 'Complexe scolaire La Colombe',
      studentFullName: anonymous.contains(paymentId) ? '' : 'Mbala Kasa Amina',
      reference: 'CF-RC-2627-000802',
      isProvisional: false,
      paidAt: DateTime(2026, 10, 12, 9, 30),
      tenders: TicketTenderLine.identityFrom(
        MoneyBag.of(const [Money(15000, 'USD')]),
      ),
      labels: labels,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cancellations implements CancellationTicketRepository {
  @override
  Future<Either<Failure, TicketCancellationModel>> buildForPayment({
    required String paymentId,
    required TicketCancellationLabels labels,
  }) async => Right(
    TicketCancellationModel(
      schoolName: 'Collège La Fontaine',
      receiptNumber: 'CF-RC-2627-000821',
      originalPaidAt: DateTime(2026, 10, 5, 12, 43),
      studentFullName: 'Mbala Kasa Amina',
      amount: MoneyBag.of(const [Money(15000, 'USD')]),
      cancelledAt: DateTime(2026, 10, 6, 9, 12),
      reason: 'Argent rendu au payeur',
      cashMoved: true,
      labels: labels,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoBand implements SchoolLogoBandLoader {
  @override
  Future<TicketLogoBand?> thermalBand(String? schoolId) async => null;
}

class _Schools implements SchoolRepository {
  @override
  Future<Either<Failure, School?>> loadCurrentSchool() async => const Right(
    School(id: 'ecole-1', name: 'EP Kimbanguiste', ticketCopies: 3),
  );

  @override
  Future<Either<Failure, SchoolLogo?>> loadCurrentSchoolLogo() async =>
      const Right(null);
}

class _FakePrinting extends PrintingPlatform {
  int laidOut = 0;
  bool fails = false;

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
    if (fails) throw StateError('aucun spouleur');
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
