import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer.dart';
import 'package:school_app_flutter/features/documents/domain/printing/thermal_printer_port.dart';
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
/// 3. **Le choix enfin.** Il est redemandé à **chaque** ticket : sur un parc où
///    une tablette peut être déplacée d'un guichet à l'autre, une imprimante
///    mémorisée est une imprimante qui sort le reçu d'un parent dans la pièce
///    d'à côté.
///
/// ⚠️ Rien ici n'est un échec d'encaissement. Le versement est **déjà écrit
/// localement** quand cette fonction s'exécute : tout ce qui suit ne coûte que
/// du papier, et le PDF reste le filet (AM-11).
Future<ThermalTicketOutcome> printThermalTicket(
  BuildContext context, {
  required TicketReceiptModel model,
}) async {
  final port = getIt<ThermalPrinterPort>();

  final ready = await _ensurePermitted(port);
  if (ready != null) return ThermalTicketFailed(ready);

  final listed = await port.pairedPrinters();
  final printers = listed.fold<List<ThermalPrinter>?>(
    (_) => null,
    (all) => all,
  );
  if (printers == null) {
    return const ThermalTicketFailed(ThermalPrinterProblem.unreachable);
  }
  if (printers.isEmpty) {
    return const ThermalTicketFailed(ThermalPrinterProblem.noPrinterSelected);
  }

  if (!context.mounted) return const ThermalTicketCancelled();
  final chosen = await showThermalPrinterPicker(context, printers: printers);
  if (chosen == null) return const ThermalTicketCancelled();

  // Un seul envoi pour tout le ticket : le canal natif préfixe chaque appel
  // d'un LF, qui tomberait entre une commande ESC/POS et son argument.
  final sent = await port.printBytes(
    EscPosTicketRenderer.render(model),
    macAddress: chosen.macAddress,
  );

  return sent.fold(
    (failure) => ThermalTicketFailed(
      failure is ThermalPrinterFailure
          ? failure.problem
          : ThermalPrinterProblem.unreachable,
    ),
    (_) => const ThermalTicketPrinted(),
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
    await permission.openSettings();
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
