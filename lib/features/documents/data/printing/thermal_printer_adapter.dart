import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_channel.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';

/// Implémente [ThermalPrinterPort] au-dessus du canal natif, et porte **toute**
/// la politique : ordre des vérifications, délais, interprétation des échecs.
///
/// ## L'ordre des appels est une garde, pas une préférence
///
/// Sans `BLUETOOTH_CONNECT` sur Android 12+, le gestionnaire natif abandonne
/// sans jamais terminer le `Future` : l'appel **pend indéfiniment**. Un seul
/// point d'entrée y échappe, `isPermissionGranted`, traité avant cette garde.
///
/// D'où l'invariant tenu ici : **rien n'est appelé avant que la permission ne
/// soit constatée**. Ce n'est pas un raffinement — c'est la différence entre un
/// message clair au guichet et un bouton « Imprimer » qui tourne pour toujours
/// avec un versement déjà encaissé derrière.
///
/// Les délais sont la **ceinture** de cette bretelle : si un jour le canal
/// pendait pour une autre raison (liaison rompue en cours d'écriture, pilote qui
/// ne rend pas la main), le guichet reçoit un échec au lieu d'un gel.
class ThermalPrinterAdapter implements ThermalPrinterPort {
  final ThermalPrinterChannel _channel;

  /// Consulté pour **constater**, jamais pour demander : solliciter une
  /// permission est un geste d'interface, et le port n'en fait aucun.
  final ThermalPrinterPermission _permission;

  /// Interrogations locales : la réponse est immédiate ou elle ne viendra pas.
  final Duration _probeTimeout;

  /// Ouverture de liaison RFCOMM — un appairage qui se réveille peut demander
  /// plusieurs secondes.
  final Duration _connectTimeout;

  /// Écriture du ticket. Généreux : un rouleau lent reste un rouleau qui
  /// imprime, et abandonner en cours d'écriture laisserait un demi-ticket.
  final Duration _writeTimeout;

  const ThermalPrinterAdapter(
    this._channel,
    this._permission, {
    Duration probeTimeout = const Duration(seconds: 5),
    Duration connectTimeout = const Duration(seconds: 15),
    Duration writeTimeout = const Duration(seconds: 20),
  }) : _probeTimeout = probeTimeout,
       _connectTimeout = connectTimeout,
       _writeTimeout = writeTimeout;

  @override
  Future<Either<Failure, Unit>> ensureReady() async {
    // 1. LES DEUX permissions, hors du canal natif — qui ne sait constater que
    //    `BLUETOOTH_CONNECT` et déclarerait tout prêt alors que `BLUETOOTH_SCAN`
    //    manque. La liaison ne s'ouvrirait pas, et l'échec se présenterait au
    //    guichet comme une imprimante hors de portée.
    final permitted = await _guard(
      () => _permission.isGranted(),
      _probeTimeout,
    );
    if (permitted != true) {
      return const Left(
        ThermalPrinterFailure(ThermalPrinterProblem.permissionDenied),
      );
    }

    // 2. Le canal, qui reste la garde de dernier recours : lui seul voit ce que
    //    le système répond réellement au plugin. Voir la note de classe.
    final granted = await _guard(
      () => _channel.isPermissionGranted(),
      _probeTimeout,
    );
    if (granted != true) {
      return const Left(
        ThermalPrinterFailure(ThermalPrinterProblem.permissionDenied),
      );
    }

    // 3. L'adaptateur allumé. À partir d'ici, un appel qui pend est anormal.
    final enabled = await _guard(
      () => _channel.isBluetoothEnabled(),
      _probeTimeout,
    );
    if (enabled != true) {
      return const Left(
        ThermalPrinterFailure(ThermalPrinterProblem.bluetoothOff),
      );
    }

    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<ThermalPrinter>>> pairedPrinters() async {
    final ready = await ensureReady();
    return ready.fold(Left.new, (_) async {
      final raw = await _guard(() => _channel.pairedDevices(), _probeTimeout);
      if (raw == null) {
        return const Left<Failure, List<ThermalPrinter>>(
          ThermalPrinterFailure(ThermalPrinterProblem.unreachable),
        );
      }

      // Une ligne illisible est ignorée, jamais fatale : une imprimante valide
      // ne doit pas disparaître de la liste parce qu'un CASQUE appairé porte un
      // nom exotique.
      final printers = [for (final line in raw) ?ThermalPrinter.tryParse(line)];
      return Right<Failure, List<ThermalPrinter>>(printers);
    });
  }

  @override
  Future<Either<Failure, Unit>> printBytes(
    Uint8List bytes, {
    required String macAddress,
  }) async {
    if (macAddress.trim().isEmpty) {
      return const Left(
        ThermalPrinterFailure(ThermalPrinterProblem.noPrinterSelected),
      );
    }

    final ready = await ensureReady();
    if (ready.isLeft()) return ready;

    // ⚠️ Fermeture d'hygiène AVANT d'ouvrir : c'est le seul geste qui sorte
    // d'une liaison déjà empoisonnée, et il n'existe aucun autre point de
    // réarmement dans l'application.
    //
    // Le canal natif garde son flux dans une variable de **portée fichier**, et
    // son `connect` s'exécute dans une coroutine que notre délai n'interrompt
    // pas : quand on abandonne à 15 s et que la socket s'ouvre trois secondes
    // plus tard, la globale est affectée et plus personne ne la referme. Sa
    // branche « déjà connecté » ne réassainit rien non plus — elle rend `false`
    // sur-le-champ. Sans cette ligne, la première connexion lente de la journée
    // condamne l'impression thermique jusqu'à la mort du processus, en
    // annonçant au guichet une imprimante « hors de portée » posée à 30 cm.
    await _silently(() => _channel.disconnect());

    final connected = await _guard(
      () => _channel.connect(macAddress),
      _connectTimeout,
    );
    if (connected != true) {
      // Symétrique du `finally` de l'écriture : un `connect` qui a échoué peut
      // tout de même avoir laissé un flux derrière lui.
      await _silently(() => _channel.disconnect());
      return const Left(
        ThermalPrinterFailure(ThermalPrinterProblem.unreachable),
      );
    }

    try {
      // UN SEUL envoi : le canal natif préfixe chaque appel d'un `LF`, qui
      // tomberait au milieu d'une séquence ESC/POS si le ticket était découpé.
      final written = await _guard(
        () => _channel.writeBytes(bytes),
        _writeTimeout,
      );
      if (written != true) {
        return const Left(
          ThermalPrinterFailure(ThermalPrinterProblem.unreachable),
        );
      }
      return const Right(unit);
    } finally {
      // La liaison se ferme quoi qu'il arrive : la laisser ouverte empêcherait
      // toute autre tablette du guichet de joindre la même imprimante, et le
      // canal natif garde son flux dans une variable de CLASSE — un échec qui
      // le laisserait en place ferait échouer l'impression suivante sans raison
      // visible.
      await _silently(() => _channel.disconnect());
    }
  }

  /// Exécute [call] borné par [limit]. Rend `null` sur dépassement **ou** sur
  /// exception : les deux veulent dire « le canal n'a pas répondu », et
  /// l'appelant en tire la même conclusion.
  Future<T?> _guard<T>(Future<T> Function() call, Duration limit) async {
    try {
      return await call().timeout(limit);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _silently(Future<void> Function() call) async {
    try {
      await call().timeout(_probeTimeout);
    } catch (_) {
      // Fermer est un geste d'hygiène : son échec n'est jamais le sujet.
    }
  }
}
