import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/dev/ticket_print_bench_page.dart';
import 'package:school_app_flutter/dev/ticket_bench_printer_store.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';

const _printer = ThermalPrinter(
  name: 'NT-8003DD',
  macAddress: 'DC:0D:30:11:22:33',
);

class _FakePort implements ThermalPrinterPort {
  ThermalPrinterProblem? problem;
  List<ThermalPrinter> printers = const [_printer];

  final List<Uint8List> printed = [];
  String? lastMac;
  int pairedCalls = 0;

  Left<Failure, T> _fail<T>() =>
      Left<Failure, T>(ThermalPrinterFailure(problem!));

  @override
  Future<Either<Failure, Unit>> ensureReady() async =>
      problem == null ? const Right(unit) : _fail<Unit>();

  @override
  Future<Either<Failure, List<ThermalPrinter>>> pairedPrinters() async {
    pairedCalls++;
    return problem == null
        ? Right<Failure, List<ThermalPrinter>>(printers)
        : _fail<List<ThermalPrinter>>();
  }

  @override
  Future<Either<Failure, Unit>> printBytes(
    Uint8List bytes, {
    required String macAddress,
  }) async {
    if (problem != null) return _fail<Unit>();
    printed.add(bytes);
    lastMac = macAddress;
    return const Right(unit);
  }
}

class _FakePermission implements ThermalPrinterPermission {
  ThermalPrinterPermissionState state = ThermalPrinterPermissionState.granted;
  int requests = 0;
  int settingsOpened = 0;

  /// Constatation initiale. Le banc ne l'interroge pas lui-même — c'est le port
  /// qui le fait — mais le double doit répondre pour rester substituable.
  bool granted = true;

  @override
  Future<bool> isGranted() async => granted;

  /// Ce que l'accord change dans le monde. Sans ce crochet, le test ne
  /// reproduirait pas la séquence réelle — c'est **l'octroi** de la permission
  /// qui débloque le port, pas le passage du temps.
  void Function()? onGranted;

  @override
  Future<ThermalPrinterPermissionState> request() async {
    requests++;
    if (state == ThermalPrinterPermissionState.granted) onGranted?.call();
    return state;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class _FakeStore implements TicketBenchPrinterStore {
  String? mac;

  @override
  Future<String?> read() async => mac;

  @override
  Future<void> write(String macAddress) async => mac = macAddress;

  @override
  Future<void> clear() async => mac = null;
}

/// Le banc est un **outil de calage matériel** : s'il tombe sur la tablette,
/// c'est une session devant l'imprimante qui est perdue. D'où ce smoke test,
/// que la galerie de composants n'a pas — elle, on la regarde, on ne s'en sert
/// pas pour régler du matériel.
void main() {
  late _FakePort port;
  late _FakePermission permission;
  late _FakeStore store;

  setUp(() {
    port = _FakePort();
    permission = _FakePermission();
    store = _FakeStore();
    getIt
      ..registerSingleton<ThermalPrinterPort>(port)
      ..registerSingleton<ThermalPrinterPermission>(permission)
      ..registerSingleton<TicketBenchPrinterStore>(store);
  });

  tearDown(getIt.reset);

  /// Surface haute : le banc est une longue liste, et un `ListView` ne
  /// construit que ce qu'il affiche. Sans ça, la sonde de page de code — qui
  /// vit tout en bas — ne serait jamais montée, et le test la déclarerait
  /// absente alors qu'elle est seulement hors champ.
  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1400, 4200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // ⚠️ Le **vrai** thème, pas celui par défaut de `MaterialApp`. Sans lui, ce
    // smoke test ne prouve rien de ce qu'il prétend prouver : `AppTheme.light`
    // impose `minimumSize: Size(double.infinity, 56)` aux `FilledButton` et
    // `OutlinedButton`, ce qui fait tomber au layout tout bouton posé inline
    // (`Row`/`Wrap`) sans override. Un banc qui se monte sous le thème neutre
    // et s'effondre sur la tablette est précisément la panne que ce fichier
    // existe pour empêcher.
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const TicketPrintBenchPage()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> load(WidgetTester tester) async {
    await tester.tap(find.text('Charger les appairées'));
    await tester.pumpAndSettle();
  }

  group('composition', () {
    testWidgets('se monte et rend les deux modèles', (tester) async {
      await pump(tester);
      expect(find.text('Banc — impression thermique'), findsOneWidget);

      // Le nom de l'école, tel que le gabarit le pose : majuscules, puis
      // translittération. « Œ » n'a pas d'octet Latin-1 et devient « OE » ;
      // « É », lui, en a un et RESTE accentué — c'est toute la différence que
      // le renderer ESC/POS devra rendre sur le papier.
      expect(find.textContaining('SACRÉ-COEUR'), findsOneWidget);

      await tester.tap(find.text('Tout absent'));
      await tester.pumpAndSettle();
      expect(find.textContaining('EP KIMBANGUISTE'), findsOneWidget);
    });

    testWidgets('change de largeur sans casser', (tester) async {
      await pump(tester);

      for (final width in const ['32', '42', '48']) {
        await tester.tap(find.text(width));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('fait varier l\'avance papier', (tester) async {
      await pump(tester);

      // Sans massicot, l'avance est le seul mécanisme qui sort la dernière
      // ligne du mécanisme : elle se cale au papier, donc le banc la balaie.
      for (final feed in const ['2', '6', '10']) {
        await tester.tap(find.text(feed));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('ESC d $feed'), findsOneWidget);
      }
    });

    testWidgets('annonce les cinq sélecteurs candidats de la sonde', (
      tester,
    ) async {
      await pump(tester);
      for (final selector in const [16, 0, 2, 19, 6]) {
        expect(find.text('ESC t $selector'), findsWidgets);
      }
    });
  });

  group('pupitre imprimante', () {
    testWidgets('liste les appairées et retient le choix', (tester) async {
      await pump(tester);
      await load(tester);

      expect(find.text('NT-8003DD'), findsOneWidget);

      await tester.tap(find.text('NT-8003DD'));
      await tester.pumpAndSettle();

      // Le couple tablette↔imprimante survit au redémarrage : c'est une
      // propriété de l'appareil, pas de la session.
      expect(store.mac, _printer.macAddress);
    });

    testWidgets('sollicite la permission quand elle manque, puis réessaie', (
      tester,
    ) async {
      // Le port ne fait que CONSTATER le refus ; demander est un geste
      // d'interface, et c'est le panneau qui le porte.
      port.problem = ThermalPrinterProblem.permissionDenied;
      permission.state = ThermalPrinterPermissionState.granted;
      permission.onGranted = () => port.problem = null;

      await pump(tester);
      await load(tester);

      expect(permission.requests, 1);
      expect(port.pairedCalls, 2, reason: 'la liste est relue après l\'accord');
      expect(find.text('NT-8003DD'), findsOneWidget);
    });

    testWidgets('ouvre les réglages sur un refus définitif', (tester) async {
      port.problem = ThermalPrinterProblem.permissionDenied;
      permission.state = ThermalPrinterPermissionState.permanentlyDenied;
      await pump(tester);
      await load(tester);

      // Redemander ne produirait plus rien : Android ne réaffiche plus la
      // boîte de dialogue. Le seul recours est la fiche de l'application.
      expect(permission.settingsOpened, 1);
      expect(find.textContaining('réglages ouverts'), findsOneWidget);
    });

    testWidgets('n\'imprime pas tant qu\'aucune imprimante n\'est choisie', (
      tester,
    ) async {
      await pump(tester);
      await load(tester);

      final button = find.widgetWithText(FilledButton, 'Imprimer le ticket');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('envoie le ticket à l\'adresse retenue', (tester) async {
      await pump(tester);
      await load(tester);
      await tester.tap(find.text('NT-8003DD'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Imprimer le ticket'));
      await tester.pumpAndSettle();

      expect(port.lastMac, _printer.macAddress);
      expect(port.printed, hasLength(1));
      // Le flux commence par `ESC @` : l'imprimante ne doit rien hériter du
      // travail précédent.
      expect(port.printed.single.take(2), equals([0x1B, 0x40]));
    });

    testWidgets('la sonde part en UN SEUL envoi, avec les 5 pages', (
      tester,
    ) async {
      await pump(tester);
      await load(tester);
      await tester.tap(find.text('NT-8003DD'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lancer la sonde'));
      await tester.pumpAndSettle();

      // Cinq connexions RFCOMM, ce serait cinq occasions d'échouer au milieu
      // de la comparaison — et un papier illisible.
      expect(port.printed, hasLength(1));
      final stream = port.printed.single;
      for (final selector in const [16, 0, 2, 19, 6]) {
        expect(
          _containsSequence(stream, [0x1B, 0x74, selector]),
          isTrue,
          reason: 'ESC t $selector absent du flux de sonde',
        );
      }
    });

    testWidgets('dit la cause exacte d\'un échec d\'envoi', (tester) async {
      await pump(tester);
      await load(tester);
      await tester.tap(find.text('NT-8003DD'));
      await tester.pumpAndSettle();

      port.problem = ThermalPrinterProblem.unreachable;
      await tester.tap(find.text('Imprimer le ticket'));
      await tester.pumpAndSettle();

      expect(find.textContaining('injoignable'), findsOneWidget);
    });
  });
}

bool _containsSequence(Uint8List haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
