import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/data/ticket/sale_ticket_composer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_model.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_print_flow.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _netum = ThermalPrinter(
  name: 'NT-8003DD',
  macAddress: 'DC:0D:30:11:22:33',
);

/// L'enchaînement de la caisse boutique, tel que le comptoir le vit :
/// **on voit le ticket, puis on l'imprime — et rien ne part sans un appui.**
///
/// ⚠️ Ce chemin n'a **aucun repli PDF**, contrairement au ticket de perception :
/// la vente est déjà écrite, et un papier de secours qui ressemblerait au reçu
/// scellé ferait exactement la confusion que l'ADR-013 refuse. Le spouleur n'est
/// donc jamais sollicité ici — et comme aucune plateforme d'impression n'est
/// installée dans ce test, tout appel au spouleur ferait lever, donc rougir.
void main() {
  late _FakePort port;
  late _FakePermission permission;
  late _FakeComposer composer;

  setUp(() {
    port = _FakePort();
    permission = _FakePermission();
    composer = _FakeComposer();
    getIt
      ..registerSingleton<ThermalPrinterPort>(port)
      ..registerSingleton<ThermalPrinterPermission>(permission)
      ..registerSingleton<SaleTicketComposer>(composer);
  });

  tearDown(getIt.reset);

  late bool? returned;

  Widget harness() => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            returned = await printSaleTicket(
              context,
              sale: _recorded(),
              levelLabels: const {},
              messenger: ScaffoldMessenger.maybeOf(context),
              // ⚠️ Aperçu de substitution OBLIGATOIRE : le vrai `PdfPreview`
              // rasterise par canal de plateforme, et son gabarit de chargement
              // anime en boucle — `pumpAndSettle` n'y rendrait jamais la main.
              previewBuilder: (_, _) => const SizedBox.shrink(),
            );
          },
          child: const Text('go'),
        ),
      ),
    ),
  );

  /// Lance le flux, puis joue l'impression et le choix de l'imprimante.
  ///
  /// [print] à faux referme l'aperçu sans rien imprimer : c'est le renoncement,
  /// et il ne doit coûter aucun papier.
  Future<void> run(
    WidgetTester tester, {
    bool print = true,
    String? choose = 'NT-8003DD',
    int more = 0,
  }) async {
    returned = null;
    await tester.pumpWidget(harness());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    if (!print) {
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      return;
    }

    await tester.tap(find.text('Imprimer'));
    await tester.pumpAndSettle();

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      for (var i = 0; i < more; i++) {
        await tester.tap(find.byTooltip('Un exemplaire de plus'));
        await tester.pump();
      }
      await tester.tap(find.text(choose ?? 'Annuler'));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('l aperçu montre le ticket avant qu il ne sorte', (tester) async {
    returned = null;
    await tester.pumpWidget(harness());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // Le titre nomme la PIÈCE, et surtout pas « Reçu de vente » : celui-là
    // désigne le scellé, et le provisoire doit rester dissemblable.
    expect(find.text('Ticket de vente'), findsOne);
    expect(find.text('Imprimer'), findsOne);
    // Rien n'est encore parti.
    expect(port.sentTo, isEmpty);
  });

  testWidgets('imprimer envoie les octets à la machine choisie', (
    tester,
  ) async {
    await run(tester);

    expect(port.sentTo, equals([_netum.macAddress]));
    expect(port.sentBytes.single, isNotEmpty);
    expect(find.text('Ticket imprimé.'), findsOne);
    // Vrai : le papier est sorti, l'appelant peut noter la trace.
    expect(returned, isTrue);
  });

  /// La boutique emprunte le même sélecteur que la perception : le compteur
  /// d'exemplaires y vient avec, sans rien à brancher de son côté.
  testWidgets('le nombre d exemplaires choisi part avec le ticket', (
    tester,
  ) async {
    await run(tester, more: 1);

    expect(port.sentBytes, hasLength(1));
    expect(port.sentCopies, equals([2]));
    expect(returned, isTrue);
  });

  /// Le contrat neuf de l'aperçu, et ce qui le rend tenable au comptoir où le
  /// papier se compte : refermer est un renoncement, et il ne coûte rien.
  testWidgets('refermer sans imprimer ne sort aucun papier', (tester) async {
    await run(tester, print: false);

    expect(port.sentTo, isEmpty);
    // Faux : marquer la trace ici ferait afficher « déjà imprimé » sur un
    // ticket que personne n'a en main.
    expect(returned, isFalse);
  });

  testWidgets('renoncer au choix de l imprimante ne marque rien', (
    tester,
  ) async {
    await run(tester, choose: null);

    expect(port.sentTo, isEmpty);
    expect(returned, isFalse);
    // Insister par un message serait reprocher au caissier son propre choix.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Bluetooth éteint : la cause est dite, et rien n est marqué', (
    tester,
  ) async {
    port.readyProblem = ThermalPrinterProblem.bluetoothOff;

    await run(tester);

    expect(
      find.text(
        'Le ticket n\'a pas pu être imprimé. La vente est enregistrée — vous '
        'pouvez réessayer.',
      ),
      findsOne,
    );
    expect(returned, isFalse);
  });
}

RecordedSale _recorded() => const RecordedSale(
  sale: BoutiqueSaleLocalModel(
    id: 'aaaabbbb-cccc-dddd-eeee-ffff00001111',
    schoolId: 'E1',
    academicYearId: 'ay-1',
    payerLastName: 'Ndombo',
    payerName: 'NDOMBO Lelo Willy',
    soldAt: '2026-08-29T11:42:00Z',
    updatedAt: 0,
  ),
  lines: [
    BoutiqueSaleLineLocalModel(
      id: 'l1',
      saleId: 'aaaabbbb-cccc-dddd-eeee-ffff00001111',
      articleId: 'art-polo',
      articleLabel: 'Polo Lacoste',
      quantity: 1,
      unitPriceInCents: 1500,
      lineTotalInCents: 1500,
      currency: 'USD',
    ),
  ],
);

/// Rend un modèle fixe : ce fichier éprouve l'ENCHAÎNEMENT, pas la composition
/// — celle-ci a ses propres tests, sur une vraie base.
class _FakeComposer implements SaleTicketComposer {
  @override
  Future<SaleTicketModel> compose(
    RecordedSale recorded, {
    required SaleTicketLabels labels,
    required Map<String, String> levelLabels,
  }) async => SaleTicketModel(
    schoolName: 'Complexe scolaire La Colombe',
    reference: 'PROV-TAB1-0001',
    isProvisional: true,
    soldAt: DateTime(2026, 8, 29, 11, 42),
    lines: const [
      SaleTicketLine(
        label: 'Polo Lacoste',
        quantity: 1,
        unitPriceInCents: 1500,
        lineTotalInCents: 1500,
        currency: 'USD',
      ),
    ],
    totals: MoneyBag.of(const [Money(1500, 'USD')]),
    labels: labels,
  );
}

class _FakePort implements ThermalPrinterPort {
  ThermalPrinterProblem? readyProblem;
  ThermalPrinterProblem? sendProblem;
  List<ThermalPrinter> printers = const [_netum];
  final List<String> sentTo = [];
  final List<int> sentCopies = [];
  final List<Uint8List> sentBytes = [];

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
    int copies = 1,
  }) async {
    sentCopies.add(copies);
    final problem = sendProblem;
    if (problem != null) return Left(ThermalPrinterFailure(problem));
    sentTo.add(macAddress);
    sentBytes.add(bytes);
    return const Right(unit);
  }
}

class _FakePermission implements ThermalPrinterPermission {
  ThermalPrinterPermissionState state = ThermalPrinterPermissionState.granted;
  int settingsOpened = 0;

  @override
  Future<bool> isGranted() async => true;

  @override
  Future<ThermalPrinterPermissionState> request() async => state;

  @override
  Future<void> openSettings() async => settingsOpened++;
}
