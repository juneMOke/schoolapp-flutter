import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';

/// Ce que l'application sait demander à une imprimante thermique.
///
/// Le port existe pour une raison précise : le paquet retenu
/// (`print_bluetooth_thermal`) n'expose que des **méthodes statiques**. Rien
/// n'y est injectable, donc rien n'y est testable, et un appelant qui
/// l'importerait directement rendrait la moitié de l'éditique non testable avec
/// lui. Tout passe par ici.
///
/// ## Ce que le port promet, et que l'implémentation doit tenir
///
/// * **Aucune méthode ne lève.** Une imprimante éteinte est un cas ordinaire de
///   guichet, pas une exception.
/// * **Aucune méthode ne pend.** Le canal natif peut ne jamais répondre (voir
///   `ThermalPrinterAdapter`) : chaque appel est borné dans le temps.
/// * **Aucune ne demande la permission.** [ensureReady] est le seul endroit qui
///   la constate ; la demander est un geste d'interface, pas de données.
abstract class ThermalPrinterPort {
  /// Vérifie ce qui doit être vrai avant d'imprimer : permission accordée,
  /// Bluetooth allumé.
  ///
  /// Séparé de [printBytes] parce qu'une interface a besoin de le savoir
  /// **avant** de proposer le geste — un bouton « Imprimer » qui échoue une fois
  /// sur deux apprend au caissier à ne plus l'utiliser.
  Future<Either<Failure, Unit>> ensureReady();

  /// Les imprimantes appairées avec la tablette. Jamais de découverte.
  Future<Either<Failure, List<ThermalPrinter>>> pairedPrinters();

  /// Envoie [bytes] à l'imprimante d'adresse [macAddress].
  ///
  /// ⚠️ **Un seul appel par ticket.** Le canal natif préfixe chaque envoi d'un
  /// saut de ligne : découper un ticket en plusieurs envois insérerait des `LF`
  /// **au milieu** du flux, entre une commande ESC/POS et son argument.
  Future<Either<Failure, Unit>> printBytes(
    Uint8List bytes, {
    required String macAddress,
  });
}
