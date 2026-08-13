import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_adapter.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_channel.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';

/// Double du canal natif, réglable piège par piège.
///
/// [hangOn] reproduit le défaut le plus grave du paquet : sans
/// `BLUETOOTH_CONNECT` sur Android 12+, le gestionnaire natif rend la main sans
/// jamais terminer le `Future`. Un `Completer` jamais complété serait fidèle
/// mais bloquerait la suite de tests ; un `Future` qui ne se résout qu'après un
/// délai très supérieur au budget de l'adaptateur teste exactement la même
/// chose, et se termine.
class _FakeChannel implements ThermalPrinterChannel {
  bool permission;
  bool bluetooth;
  List<String> paired;
  bool connects;
  bool writes;
  Set<String> hangOn;
  Set<String> throwOn;

  final List<String> calls = [];
  final List<List<int>> written = [];

  _FakeChannel({
    this.permission = true,
    this.bluetooth = true,
    this.paired = const [],
    this.connects = true,
    this.writes = true,
    this.hangOn = const {},
    this.throwOn = const {},
  });

  Future<T> _record<T>(String name, T value) async {
    calls.add(name);
    if (throwOn.contains(name)) throw StateError('canal en panne : $name');
    if (hangOn.contains(name)) {
      await Future<void>.delayed(const Duration(seconds: 30));
    }
    return value;
  }

  @override
  Future<bool> isPermissionGranted() => _record('permission', permission);

  @override
  Future<bool> isBluetoothEnabled() => _record('bluetooth', bluetooth);

  @override
  Future<List<String>> pairedDevices() => _record('paired', paired);

  @override
  Future<bool> connect(String macAddress) {
    calls.add('connect:$macAddress');
    return _record('connect', connects);
  }

  @override
  Future<bool> writeBytes(List<int> bytes) {
    written.add(bytes);
    return _record('write', writes);
  }

  @override
  Future<void> disconnect() => _record('disconnect', null);
}

/// Double de la constatation de permission.
///
/// `request` et `openSettings` lèvent **volontairement** : le port promet de ne
/// jamais solliciter l'utilisateur, et ce double transforme cette promesse en
/// échec de test si elle est rompue un jour.
class _FakePermission implements ThermalPrinterPermission {
  _FakePermission({this.granted = true});

  final bool granted;
  int checks = 0;

  @override
  Future<bool> isGranted() async {
    checks++;
    return granted;
  }

  @override
  Future<ThermalPrinterPermissionState> request() async =>
      throw StateError('Le port ne DEMANDE jamais la permission.');

  @override
  Future<void> openSettings() async =>
      throw StateError('Le port n\'ouvre jamais les réglages.');
}

ThermalPrinterAdapter _adapter(
  _FakeChannel channel, {
  ThermalPrinterPermission? permission,
}) => ThermalPrinterAdapter(
  channel,
  permission ?? _FakePermission(),
  // Budgets courts : les tests portent sur la POLITIQUE, pas sur l'horloge.
  probeTimeout: const Duration(milliseconds: 40),
  connectTimeout: const Duration(milliseconds: 40),
  writeTimeout: const Duration(milliseconds: 40),
);

ThermalPrinterProblem? _problemOf(Object either) {
  final failure = (either as dynamic).fold((f) => f, (_) => null) as Failure?;
  return failure is ThermalPrinterFailure ? failure.problem : null;
}

final Uint8List _ticket = Uint8List.fromList([0x1B, 0x40, 0x41]);

void main() {
  group('ensureReady', () {
    test(
      'exige la permission AVANT de regarder quoi que ce soit d\'autre',
      () async {
        final channel = _FakeChannel(permission: false);

        final result = await _adapter(channel).ensureReady();

        expect(_problemOf(result), ThermalPrinterProblem.permissionDenied);
        // L'invariant du lot : sans permission, on ne touche à RIEN d'autre —
        // c'est ce qui empêche l'appel qui pend indéfiniment.
        expect(channel.calls, equals(['permission']));
      },
    );

    /// La panne du 2026-08-11, en un test : `BLUETOOTH_CONNECT` accordée,
    /// `BLUETOOTH_SCAN` non. Le canal natif ne voit que la première et déclare
    /// tout prêt ; l'impression échoue ensuite dans `connect()`, et le guichet
    /// lit « imprimante injoignable » — un diagnostic faux, qui envoie chercher
    /// la panne du côté du matériel.
    test('une permission accordée À MOITIÉ est un refus', () async {
      final channel = _FakeChannel();

      final result = await _adapter(
        channel,
        permission: _FakePermission(granted: false),
      ).ensureReady();

      expect(_problemOf(result), ThermalPrinterProblem.permissionDenied);
      // Le canal n'est même pas consulté : sa réponse serait trompeuse.
      expect(channel.calls, isEmpty);
    });

    test('distingue le Bluetooth éteint du refus de permission', () async {
      final channel = _FakeChannel(bluetooth: false);

      expect(
        _problemOf(await _adapter(channel).ensureReady()),
        ThermalPrinterProblem.bluetoothOff,
      );
    });

    test('passe quand tout est en place', () async {
      final result = await _adapter(_FakeChannel()).ensureReady();
      expect(result.isRight(), isTrue);
    });

    test('un canal qui PEND rend un échec, jamais un gel', () async {
      final channel = _FakeChannel(hangOn: {'permission'});

      final result = await _adapter(channel).ensureReady();

      expect(_problemOf(result), ThermalPrinterProblem.permissionDenied);
    });

    test('un canal qui LÈVE est traité comme un canal muet', () async {
      final channel = _FakeChannel(throwOn: {'bluetooth'});

      expect(
        _problemOf(await _adapter(channel).ensureReady()),
        ThermalPrinterProblem.bluetoothOff,
      );
    });
  });

  group('pairedPrinters', () {
    test('lit le format « nom#MAC » du canal', () async {
      final channel = _FakeChannel(
        paired: const [
          'NT-8003DD#DC:0D:30:11:22:33',
          'Casque#AA:BB:CC:DD:EE:FF',
        ],
      );

      final result = await _adapter(channel).pairedPrinters();

      expect(
        result.getOrElse(() => []),
        equals(const [
          ThermalPrinter(name: 'NT-8003DD', macAddress: 'DC:0D:30:11:22:33'),
          ThermalPrinter(name: 'Casque', macAddress: 'AA:BB:CC:DD:EE:FF'),
        ]),
      );
    });

    test('ignore une ligne illisible sans perdre les autres', () async {
      final channel = _FakeChannel(
        paired: const [
          'sans separateur',
          'NT-8003DD#DC:0D:30:11:22:33',
          'vide#',
        ],
      );

      final printers = (await _adapter(
        channel,
      ).pairedPrinters()).getOrElse(() => []);

      expect(printers, hasLength(1));
      expect(printers.single.macAddress, 'DC:0D:30:11:22:33');
    });

    /// ⚠️ Ce test ne vaut que parce que le canal rend désormais les lignes
    /// **brutes**. Tant qu'il recomposait `'<nom>#<mac>'` depuis l'objet du
    /// paquet — lequel avait déjà découpé sur le PREMIER `#` —, « Guichet #1 »
    /// arrivait ici en `'Guichet #1'` avec l'adresse « 1 », et ce test restait
    /// vert en ne prouvant rien du chemin réel.
    test('un nom contenant « # » ne casse pas l\'adresse', () async {
      final channel = _FakeChannel(paired: const ['POS#2#DC:0D:30:11:22:33']);

      final printers = (await _adapter(
        channel,
      ).pairedPrinters()).getOrElse(() => []);

      expect(printers.single.name, 'POS#2');
      expect(printers.single.macAddress, 'DC:0D:30:11:22:33');
    });

    test(
      'remonte le refus de permission sans interroger les appareils',
      () async {
        final channel = _FakeChannel(permission: false);

        expect(
          _problemOf(await _adapter(channel).pairedPrinters()),
          ThermalPrinterProblem.permissionDenied,
        );
        expect(channel.calls, isNot(contains('paired')));
      },
    );
  });

  group('printBytes', () {
    const mac = 'DC:0D:30:11:22:33';

    test('envoie le ticket en UN SEUL appel', () async {
      final channel = _FakeChannel();

      final result = await _adapter(
        channel,
      ).printBytes(_ticket, macAddress: mac);

      expect(result.isRight(), isTrue);
      // Découper l'envoi ferait insérer par le canal natif un `LF` au milieu du
      // flux, entre une commande ESC/POS et son argument.
      expect(channel.written, hasLength(1));
      expect(channel.written.single, equals(_ticket));
    });

    test('ferme la liaison même quand l\'écriture échoue', () async {
      final channel = _FakeChannel(writes: false);

      final result = await _adapter(
        channel,
      ).printBytes(_ticket, macAddress: mac);

      expect(_problemOf(result), ThermalPrinterProblem.unreachable);
      // Le canal natif garde son flux dans une variable de CLASSE : le laisser
      // ouvert ferait échouer l'impression SUIVANTE sans raison visible.
      expect(channel.calls, contains('disconnect'));
    });

    test('ferme la liaison aussi quand l\'écriture PEND', () async {
      final channel = _FakeChannel(hangOn: {'write'});

      final result = await _adapter(
        channel,
      ).printBytes(_ticket, macAddress: mac);

      expect(_problemOf(result), ThermalPrinterProblem.unreachable);
      expect(channel.calls, contains('disconnect'));
    });

    test(
      'une adresse vide se dit « aucune imprimante », pas « injoignable »',
      () async {
        final channel = _FakeChannel();

        final result = await _adapter(
          channel,
        ).printBytes(_ticket, macAddress: ' ');

        expect(_problemOf(result), ThermalPrinterProblem.noPrinterSelected);
        // Rien n'est tenté : le guichet doit choisir, pas rallumer.
        expect(channel.calls, isEmpty);
      },
    );

    test(
      'une imprimante éteinte est « injoignable », et rien n\'est écrit',
      () async {
        final channel = _FakeChannel(connects: false);

        final result = await _adapter(
          channel,
        ).printBytes(_ticket, macAddress: mac);

        expect(_problemOf(result), ThermalPrinterProblem.unreachable);
        expect(channel.written, isEmpty);
        // La liaison est refermée même quand elle n'a pas pu s'ouvrir : le
        // canal natif garde son flux dans une variable de portée fichier, et
        // un `connect` échoué peut tout de même en laisser un derrière lui.
        expect(channel.calls.last, 'disconnect');
      },
    );

    /// Le pire cas du lot, et celui qu'aucun test ne couvrait : le délai de
    /// connexion tombe, mais la coroutine native poursuit et finit par ouvrir
    /// la socket. Sans fermeture d'hygiène en entrée, la liaison reste ouverte
    /// pour la durée du processus et TOUTES les impressions suivantes échouent
    /// instantanément — imprimante allumée, à portée, message trompeur.
    test('un connect qui PEND laisse la liaison refermée', () async {
      final channel = _FakeChannel(hangOn: {'connect'});

      final result = await _adapter(
        channel,
      ).printBytes(_ticket, macAddress: mac);

      expect(_problemOf(result), ThermalPrinterProblem.unreachable);
      expect(channel.written, isEmpty);
      expect(
        channel.calls.where((call) => call == 'disconnect'),
        hasLength(2),
        reason:
            'une fermeture en entrée pour désempoisonner, une en sortie pour '
            'ne pas laisser la socket que le natif vient peut-être d\'ouvrir',
      );
    });

    test('la permission est constatée avant la moindre connexion', () async {
      final channel = _FakeChannel(permission: false);

      final result = await _adapter(
        channel,
      ).printBytes(_ticket, macAddress: mac);

      expect(_problemOf(result), ThermalPrinterProblem.permissionDenied);
      expect(channel.calls, equals(['permission']));
    });
  });
}
