import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_channel.dart';

/// Le seul fichier du dépôt qui touche `print_bluetooth_thermal`.
///
/// Il ne contient **aucune politique** — ni délai, ni ordre d'appel, ni
/// interprétation d'un échec. Tout cela vit dans `ThermalPrinterAdapter`, où
/// c'est testable. Ici, on ne fait que traverser.
///
/// ## Ce que le canal natif fait vraiment, et qu'il faut savoir en amont
///
/// Vérifié dans le source Kotlin du paquet (v1.2.2), pas déduit de sa
/// documentation :
///
/// 1. **`writeBytes` préfixe le flux d'un `\n`.** La liste reçue est concaténée
///    derrière `"\n".toByteArray()`. Conséquences : une ligne blanche en tête de
///    chaque ticket, et surtout **l'interdiction de découper un ticket en
///    plusieurs envois** — un `LF` tomberait entre une commande ESC/POS et son
///    argument. (Le découpage en blocs de 16 Ko, lui, est interne à un seul
///    appel et n'ajoute rien.)
/// 2. **`connectionStatus` ÉCRIT une espace** sur le flux pour tester la
///    liaison. On ne l'expose donc pas : sonder l'état imprimerait un caractère.
/// 3. **`writebytes` attend une liste GÉNÉRIQUE**, pas un `Uint8List` : le
///    gestionnaire Kotlin fait `call.arguments as List<Int>`. D'où la conversion
///    dans [writeBytes] — voir la note qui l'accompagne.
/// 4. ⚠️ **Le plus grave — sans `BLUETOOTH_CONNECT` sur Android 12+, le
///    gestionnaire natif `return` sans jamais appeler `result`.** Le `Future`
///    Dart ne se termine **jamais**. Seul `isPermissionGranted` échappe à cette
///    garde, parce qu'il est traité avant elle. D'où la règle de l'adaptateur :
///    constater la permission AVANT tout autre appel, et borner chaque appel
///    dans le temps par sécurité.
class PrintBluetoothThermalChannel implements ThermalPrinterChannel {
  const PrintBluetoothThermalChannel();

  @override
  Future<bool> isPermissionGranted() =>
      PrintBluetoothThermal.isPermissionBluetoothGranted;

  @override
  Future<bool> isBluetoothEnabled() => PrintBluetoothThermal.bluetoothEnabled;

  /// ⚠️ **Lecture directe du canal de méthode, sans passer par le wrapper du
  /// paquet** — le seul endroit du dépôt où c'est fait, et pour une raison
  /// vérifiable dans son source.
  ///
  /// Le natif concatène `"$nom#$adresse"` **sans échapper le nom**, et le
  /// wrapper Dart redécoupe sur le **premier** `#` (`item.split("#")`, puis
  /// `info[0]`/`info[1]`). Une imprimante nommée « Guichet #1 » ressort donc
  /// avec le nom « Guichet » et l'adresse « 1 » : on tenterait d'ouvrir une
  /// liaison RFCOMM vers une adresse qui n'existe pas, et le guichet lirait
  /// « imprimante injoignable » sur une machine allumée devant lui.
  ///
  /// En rendant les lignes brutes, le découpage revient à `ThermalPrinter
  /// .tryParse`, qui coupe sur le **dernier** `#` — la seule lecture correcte,
  /// une adresse MAC n'en contenant jamais.
  @override
  Future<List<String>> pairedDevices() async {
    const channel = MethodChannel('groons.web.app/print');
    final raw = await channel.invokeMethod<List<Object?>>('pairedbluetooths');
    return [
      for (final line in raw ?? const <Object?>[])
        if (line is String) line,
    ];
  }

  @override
  Future<bool> connect(String macAddress) =>
      PrintBluetoothThermal.connect(macPrinterAddress: macAddress);

  @override
  Future<bool> writeBytes(List<int> bytes) =>
      // ⚠️ `List<int>.from` n'est pas une précaution de style, c'est la
      // condition pour que le ticket parte. Le plugin fait
      // `call.arguments as List<Int>` (PrintBluetoothThermalPlugin.kt:145),
      // alors que le codec standard de Flutter sérialise un `Uint8List` par son
      // type dédié — il arrive côté Java en `byte[]`, jamais en `java.util.List`.
      //
      // Or c'est exactement ce que produit `EscPosTicketRenderer`. Passer le
      // flux tel quel lève `ClassCastException: byte[] cannot be cast to
      // java.util.List`, et le fait APRÈS l'ouverture de la liaison RFCOMM :
      // l'imprimante est connectée, prête, et ne reçoit rien.
      PrintBluetoothThermal.writeBytes(List<int>.from(bytes));

  @override
  Future<void> disconnect() => PrintBluetoothThermal.disconnect;
}
