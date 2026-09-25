import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

const _netum = ThermalPrinter(
  name: 'NT-8003DD',
  macAddress: 'DC:0D:30:11:22:33',
);
const _other = ThermalPrinter(name: 'POS-58', macAddress: 'AA:BB:CC:DD:EE:FF');

class _FakePort implements ThermalPrinterPort {
  ThermalPrinterProblem? readyProblem;
  ThermalPrinterProblem? sendProblem;
  List<ThermalPrinter> printers = const [_netum];

  int readyCalls = 0;
  final List<String> sentTo = [];
  final List<int> sentCopies = [];
  final List<Uint8List> sent = [];

  @override
  Future<Either<Failure, Unit>> ensureReady() async {
    readyCalls++;
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
    int copies = 1,
  }) async {
    sentCopies.add(copies);
    final problem = sendProblem;
    if (problem != null) return Left(ThermalPrinterFailure(problem));
    sent.add(bytes);
    sentTo.add(macAddress);
    return const Right(unit);
  }
}

class _FakePermission implements ThermalPrinterPermission {
  ThermalPrinterPermissionState state = ThermalPrinterPermissionState.granted;
  int requests = 0;
  int settingsOpened = 0;

  /// Ce que l'octroi change dans le monde : sans ce crochet, le test ne
  /// reproduirait pas la séquence réelle — c'est l'accord qui débloque le port.
  void Function()? onGranted;

  @override
  Future<bool> isGranted() async => true;

  @override
  Future<ThermalPrinterPermissionState> request() async {
    requests++;
    if (state == ThermalPrinterPermissionState.granted) onGranted?.call();
    return state;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

final TicketReceiptModel _model = TicketReceiptModel(
  schoolName: 'Complexe scolaire Sacré-Cœur',
  studentFullName: 'Amina Ndombasi',
  reference: 'PROV-TAB1-0001',
  isProvisional: true,
  paidAt: DateTime(2026, 8, 12, 9, 30),
  tenders: TicketTenderLine.identityFrom(
    MoneyBag.of(const [Money(2500000, 'CDF')]),
  ),
  labels: const TicketLabels(
    documentTitle: 'Ticket de perception',
    provisionalMention: 'provisoire',
    referenceLabel: 'Réf.',
    dateLabel: 'Date :',
    payerLabel: 'PAYEUR :',
    phoneLabel: 'Tél.',
    cashierLabel: 'Caissier :',
    schoolPhoneLabel: 'Tél. Promoteur :',
    tillPhoneLabel: 'Tél. caisse :',
    studentLabel: 'Élève :',
    matriculationLabel: 'Matricule :',
    annualMatriculationLabel: 'Mat. annuel :',
    classroomLabel: 'Classe :',
    amountReceivedLabel: 'Montant reçu',
    rateLabel: 'Taux',
    derivedAmountPrefix: 'soit',
    allocationsLabel: 'Répartition',
    advanceLabel: 'Avance',
    balanceLabel: 'Solde restant à payer pour ce(s) frais',
    balanceTotalLabel: 'Total',
    historyLabel: 'Historique des paiements',
    historyTotalLabel: 'Total verse',
    signatureLabel: 'Signature du caissier',
    keepTicketNotice: 'Conservez ce ticket.',
    thanksNotice: 'Merci.',
    editorNotice: 'Recu edite par ETEELO CONNECT',
    editorSite: 'eteeloconnect.com',
  ),
);

void main() {
  late _FakePort port;
  late _FakePermission permission;

  setUp(() {
    port = _FakePort();
    permission = _FakePermission();
    getIt
      ..registerSingleton<ThermalPrinterPort>(port)
      ..registerSingleton<ThermalPrinterPermission>(permission);
  });

  tearDown(getIt.reset);

  /// Monte un contexte, lance l'impression, et laisse le dialogue s'afficher.
  ///
  /// [choose] est joué une fois la liste ouverte : le nom de l'imprimante à
  /// taper, ou `null` pour fermer sans choisir.
  /// [more] appuie autant de fois sur (+) avant de choisir.
  Future<ThermalTicketOutcome> print(
    WidgetTester tester, {
    String? choose = 'NT-8003DD',
    int more = 0,
    int initialCopies = 1,
  }) async {
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

    final pending = printThermalTicket(
      captured,
      model: _model,
      initialCopies: initialCopies,
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < more; i++) {
      await tester.tap(find.byTooltip('Un exemplaire de plus'));
      await tester.pump();
    }

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text(choose ?? 'Annuler'));
      await tester.pumpAndSettle();
    }

    return pending;
  }

  group('impression', () {
    testWidgets('envoie le ticket à l\'imprimante choisie', (tester) async {
      final outcome = await print(tester);

      expect(outcome, isA<ThermalTicketPrinted>());
      expect(port.sentTo, equals([_netum.macAddress]));
      // Un seul envoi : le canal natif préfixe chaque appel d'un LF, qui
      // tomberait entre une commande ESC/POS et son argument.
      expect(port.sent, hasLength(1));
      // Le flux commence par la remise à zéro, jamais par du texte.
      expect(port.sent.single.take(2), equals([0x1B, 0x40]));
    });

    testWidgets('demande le choix à CHAQUE ticket', (tester) async {
      port.printers = const [_netum, _other];

      await print(tester);
      await print(tester, choose: 'POS-58');

      // Rien n'est mémorisé : une tablette déplacée d'un guichet à l'autre ne
      // doit pas sortir le reçu d'un parent dans la pièce d'à côté.
      expect(port.sentTo, equals([_netum.macAddress, _other.macAddress]));
    });

    testWidgets('une liste fermée n\'imprime rien et n\'est pas un échec', (
      tester,
    ) async {
      final outcome = await print(tester, choose: null);

      // Surtout pas un échec : l'appelant replierait sur le PDF, donc ouvrirait
      // le spouleur système sous les doigts de quelqu'un qui vient d'annuler.
      expect(outcome, isA<ThermalTicketCancelled>());
      expect(port.sent, isEmpty);
    });
  });

  group('exemplaires', () {
    String shown(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('ticketCopiesValue')))
        .data!;

    IconButton button(WidgetTester tester, String tooltip) =>
        tester.widget<IconButton>(
          find.ancestor(
            of: find.byTooltip(tooltip),
            matching: find.byType(IconButton),
          ),
        );

    testWidgets('par défaut, un seul exemplaire', (tester) async {
      await print(tester);

      expect(port.sentCopies, equals([1]));
    });

    testWidgets('le compteur réglé part avec l\'imprimante choisie', (
      tester,
    ) async {
      final outcome = await print(tester, more: 2);

      expect(outcome, isA<ThermalTicketPrinted>());
      // UN envoi, qui porte le nombre : c'est le port qui assemble.
      expect(port.sent, hasLength(1));
      expect(port.sentCopies, equals([3]));
    });

    testWidgets('le défaut de l\'appelant est le point de départ', (
      tester,
    ) async {
      await print(tester, initialCopies: 2);

      expect(port.sentCopies, equals([2]));
    });

    testWidgets('le compteur est borné des deux côtés', (tester) async {
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
      unawaited(printThermalTicket(captured, model: _model));
      await tester.pumpAndSettle();

      expect(shown(tester), '1');
      expect(button(tester, 'Un exemplaire de moins').onPressed, isNull);

      for (var i = 0; i < 10; i++) {
        final plus = button(tester, 'Un exemplaire de plus');
        if (plus.onPressed == null) break;
        plus.onPressed!();
        await tester.pump();
      }

      // Une erreur de saisie ne doit pas pouvoir vider le rouleau.
      expect(shown(tester), '${TicketCopies.max}');
      expect(button(tester, 'Un exemplaire de plus').onPressed, isNull);
      expect(button(tester, 'Un exemplaire de moins').onPressed, isNotNull);
    });

    testWidgets('un envoi raté rend le nombre choisi, pour le repli PDF', (
      tester,
    ) async {
      port.sendProblem = ThermalPrinterProblem.unreachable;

      final outcome = await print(tester, more: 1);

      expect((outcome as ThermalTicketFailed).copies, 2);
    });

    testWidgets('un échec AVANT le choix ne prétend aucun nombre', (
      tester,
    ) async {
      port.readyProblem = ThermalPrinterProblem.bluetoothOff;

      final outcome = await print(tester);

      // Personne n'a vu le compteur : c'est au défaut de l'appelant de
      // trancher, pas à un « 1 » inventé ici.
      expect((outcome as ThermalTicketFailed).copies, isNull);
    });
  });

  group('causes annoncées', () {
    testWidgets('aucune imprimante appairée : pas de liste vide', (
      tester,
    ) async {
      port.printers = const [];

      final outcome = await print(tester);

      expect(
        (outcome as ThermalTicketFailed).problem,
        ThermalPrinterProblem.noPrinterSelected,
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Bluetooth éteint : dit avant d\'ouvrir quoi que ce soit', (
      tester,
    ) async {
      port.readyProblem = ThermalPrinterProblem.bluetoothOff;

      final outcome = await print(tester);

      expect(
        (outcome as ThermalTicketFailed).problem,
        ThermalPrinterProblem.bluetoothOff,
      );
      expect(permission.requests, isZero);
    });

    testWidgets('imprimante injoignable à l\'envoi', (tester) async {
      port.sendProblem = ThermalPrinterProblem.unreachable;

      final outcome = await print(tester);

      expect(
        (outcome as ThermalTicketFailed).problem,
        ThermalPrinterProblem.unreachable,
      );
    });
  });

  group('permission', () {
    testWidgets('sollicitée sur refus, puis l\'impression reprend', (
      tester,
    ) async {
      port.readyProblem = ThermalPrinterProblem.permissionDenied;
      // L'accord débloque le port : c'est la séquence réelle du guichet.
      permission.onGranted = () => port.readyProblem = null;

      final outcome = await print(tester);

      expect(permission.requests, 1);
      expect(outcome, isA<ThermalTicketPrinted>());
    });

    testWidgets('un refus reste un refus, sans insister', (tester) async {
      port.readyProblem = ThermalPrinterProblem.permissionDenied;
      permission.state = ThermalPrinterPermissionState.denied;

      final outcome = await print(tester);

      expect(
        (outcome as ThermalTicketFailed).problem,
        ThermalPrinterProblem.permissionDenied,
      );
      expect(permission.requests, 1);
      expect(permission.settingsOpened, isZero);
    });

    /// Le refus définitif se **dit**, il ne détourne pas.
    ///
    /// Ce geste a été retiré d'ici : `openAppSettings` bascule sur une autre
    /// activité et rend la main aussitôt, si bien que le message de cause puis
    /// le spouleur PDF s'ouvraient derrière une application déjà passée en
    /// arrière-plan. Le caissier revenait des réglages sur un ticket qu'il
    /// n'avait pas vu partir. Les réglages sont désormais une **action portée
    /// par le message** (cf. provisional_ticket_print_flow), donc un choix.
    testWidgets('un refus définitif ne détourne pas vers les réglages', (
      tester,
    ) async {
      port.readyProblem = ThermalPrinterProblem.permissionDenied;
      permission.state = ThermalPrinterPermissionState.permanentlyDenied;

      final outcome = await print(tester);

      expect(permission.settingsOpened, isZero);
      // La cause remonte quand même : c'est elle qui portera l'action.
      expect(
        (outcome as ThermalTicketFailed).problem,
        ThermalPrinterProblem.permissionDenied,
      );
    });
  });
}
