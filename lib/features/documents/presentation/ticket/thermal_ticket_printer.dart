import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_copies.dart';
import 'package:school_app_flutter/features/documents/domain/printing/ticket_printer_settings.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_logo_band.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_printer_picker.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';

/// Sort [model] sur une imprimante thermique choisie par le caissier.
///
/// ## L'ordre des gestes, et pourquoi il est celui-là
///
/// 1. **La permission d'abord**, parce que tout le reste en dépend et qu'un
///    refus doit se dire avant d'avoir ouvert quoi que ce soit. La demander est
///    un geste d'interface : le port ne fait que la constater, c'est ici qu'on
///    sollicite l'utilisateur.
/// 2. **La liste ensuite**, résolue avant d'ouvrir la moindre boîte de
///    dialogue : une liste vide n'est pas un écran à montrer, c'est une cause à
///    dire — et le repli PDF derrière.
/// 3. **L'imprimante enfin** : celle de la tablette (Finances ▸ Imprimante de
///    tickets), sans question. Sans imprimante retenue, ou si elle n'est plus
///    appairée, le sélecteur s'ouvre une fois et son choix est retenu. Décision
///    du 2026-11-16 : le choix redemandé à chaque ticket protégeait d'une
///    tablette déplacée d'un guichet à l'autre, mais pesait sur chaque
///    impression ; l'écran dit désormais sur quelle imprimante le ticket est
///    parti, et l'imprimante se change dans les réglages.
///
/// ⚠️ Rien ici n'est un échec d'encaissement. Le versement est **déjà écrit
/// localement** quand cette fonction s'exécute : tout ce qui suit ne coûte que
/// du papier, et le PDF reste le filet (AM-11).
Future<ThermalTicketOutcome> printThermalTicket(
  BuildContext context, {
  required TicketReceiptModel model,
  TicketLogoBand? logoBand,
  int initialCopies = TicketCopies.fallback,
}) => printThermalBytes(
  context,
  bytes: EscPosTicketRenderer.render(model, logoBand: logoBand),
  initialCopies: initialCopies,
);

/// Le même parcours, à partir d'octets **déjà rendus**.
///
/// Extrait pour que la caisse boutique l'emprunte : tout ce qui précède l'envoi
/// — permission, liste, choix de l'imprimante — ne dépend pas de ce qu'on
/// imprime, et deux copies de ce parcours divergeraient sur la seule chose qui
/// compte, l'ordre des trois questions.
///
/// C'est aussi ce qui garde la **même imprimante** pour tous les tickets :
/// il n'y a aucune raison qu'un reçu parte ailleurs qu'une vente.
///
/// [bytes] est **un** exemplaire : la répétition appartient au port, qui seul
/// sait l'assembler en un envoi unique.
Future<ThermalTicketOutcome> printThermalBytes(
  BuildContext context, {
  required Uint8List bytes,
  int initialCopies = TicketCopies.fallback,
}) async {
  final chosen = await chooseThermalPrinter(
    context,
    initialCopies: initialCopies,
  );
  return chosen.fold((outcome) async => outcome, (choice) async {
    final problem = await sendThermalBytes(bytes, choice);
    return problem == null
        ? ThermalTicketPrinted(printer: choice.printer)
        : ThermalTicketFailed(problem, copies: choice.copies);
  });
}

/// La forme de [chooseThermalPrinter], pour qui doit la remplacer.
typedef ThermalPrinterChooser =
    Future<Either<ThermalTicketOutcome, ThermalPrintChoice>> Function(
      BuildContext context, {
      int initialCopies,
    });

/// La forme de [sendThermalBytes], pour qui doit la remplacer.
typedef ThermalBytesSender =
    Future<ThermalPrinterProblem?> Function(
      Uint8List bytes,
      ThermalPrintChoice choice,
    );

/// Les trois questions avant tout envoi — permission, liste, choix de
/// l'imprimante et du nombre d'exemplaires —, sans rien envoyer.
///
/// Séparé de l'envoi pour l'impression **par lot** de « Tickets à imprimer »
/// (continuité des tickets RC, lot D) : l'imprimante s'y choisit une fois pour
/// tout le lot, et les tickets partent ensuite un par un.
///
/// À gauche, l'issue qui dispense d'envoyer : échec, renonciation, surface
/// disparue.
Future<Either<ThermalTicketOutcome, ThermalPrintChoice>> chooseThermalPrinter(
  BuildContext context, {
  int initialCopies = TicketCopies.fallback,
}) async {
  final port = getIt<ThermalPrinterPort>();

  final ready = await _ensurePermitted(port);
  if (ready != null) return Left(ThermalTicketFailed(ready));

  final listed = await port.pairedPrinters();
  final printers = listed.fold<List<ThermalPrinter>?>(
    (_) => null,
    (all) => all,
  );
  if (printers == null) {
    return const Left(ThermalTicketFailed(ThermalPrinterProblem.unreachable));
  }
  if (printers.isEmpty) {
    return const Left(
      ThermalTicketFailed(ThermalPrinterProblem.noPrinterSelected),
    );
  }

  // L'imprimante de cette tablette (Finances ▸ Imprimante de tickets) : le
  // ticket y part sans question, tant qu'elle reste appairée. Son nom est
  // relu dans la liste, celui du jour.
  final settings = getIt<TicketPrinterSettingsStore>();
  final remembered = (await settings.read()).printer;
  final paired = remembered == null
      ? null
      : printers
            .where((p) => p.macAddress == remembered.macAddress)
            .firstOrNull;
  if (paired != null) {
    return Right(
      ThermalPrintChoice(
        printer: paired,
        copies: TicketCopies.clamp(initialCopies),
      ),
    );
  }

  // La modale a disparu pendant la préparation : plus personne à qui demander
  // l'imprimante. Ce n'est PAS une renonciation — l'appelant doit encore
  // produire un papier, par le repli.
  if (!context.mounted) return const Left(ThermalTicketNoSurface());

  final chosen = await showThermalPrinterPicker(
    context,
    printers: printers,
    initialCopies: initialCopies,
  );
  if (chosen == null) return const Left(ThermalTicketCancelled());
  // Choisie une fois, retenue : les tickets suivants y partent directement.
  await settings.savePrinter(chosen.printer);
  return Right(chosen);
}

/// Envoie [bytes] — **un** exemplaire — à l'imprimante de [choice], autant de
/// fois qu'il le demande. `null` si l'envoi a réussi, sinon sa cause.
Future<ThermalPrinterProblem?> sendThermalBytes(
  Uint8List bytes,
  ThermalPrintChoice choice,
) async {
  // Un seul envoi pour tout le ticket, exemplaires compris : le canal natif
  // préfixe chaque appel d'un LF, qui tomberait entre une commande ESC/POS et
  // son argument.
  final sent = await getIt<ThermalPrinterPort>().printBytes(
    bytes,
    macAddress: choice.printer.macAddress,
    copies: choice.copies,
  );
  return sent.fold(
    (failure) => failure is ThermalPrinterFailure
        ? failure.problem
        : ThermalPrinterProblem.unreachable,
    (_) => null,
  );
}

/// Rend `null` quand tout est en place, sinon la cause à annoncer.
///
/// Sollicite l'utilisateur **une seule fois**, et seulement sur un refus
/// constaté : redemander une permission déjà accordée n'affiche rien, mais
/// redemander une permission refusée définitivement n'affiche plus rien non
/// plus — d'où le passage par les réglages, seul recours restant.
Future<ThermalPrinterProblem?> _ensurePermitted(ThermalPrinterPort port) async {
  final ready = await port.ensureReady();
  final problem = ready.fold(
    (failure) => failure is ThermalPrinterFailure ? failure.problem : null,
    (_) => null,
  );
  if (problem != ThermalPrinterProblem.permissionDenied) return problem;

  final permission = getIt<ThermalPrinterPermission>();
  final state = await permission.request();
  if (state == ThermalPrinterPermissionState.permanentlyDenied) {
    // ⚠️ On n'ouvre PAS les réglages ici. Ce fut le cas, et l'enchaînement
    // était intenable : `openAppSettings` bascule sur une autre activité et
    // rend la main aussitôt, si bien que le message de cause puis le spouleur
    // PDF s'ouvraient derrière, dans une application passée en arrière-plan.
    // Le caissier revenait des réglages sur un ticket qu'il n'avait pas vu
    // partir, ou pas partir du tout.
    //
    // L'appelant décide : il annonce la cause pendant que l'écran est encore
    // là, puis propose les réglages comme geste terminal.
    return ThermalPrinterProblem.permissionDenied;
  }
  if (state != ThermalPrinterPermissionState.granted) {
    return ThermalPrinterProblem.permissionDenied;
  }

  // Accordée à l'instant : on reprend la vérification complète, car le
  // Bluetooth peut très bien être éteint derrière.
  final retried = await port.ensureReady();
  return retried.fold(
    (failure) => failure is ThermalPrinterFailure
        ? failure.problem
        : ThermalPrinterProblem.unreachable,
    (_) => null,
  );
}
