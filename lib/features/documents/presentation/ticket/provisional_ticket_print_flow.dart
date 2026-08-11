import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_printer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sort le ticket provisoire du versement [paymentId] : **la thermique
/// d'abord, le PDF en filet**.
///
/// L'ordre vient de l'ADR-012 (AM-11) : le PDF n'est pas une seconde sortie
/// qu'on proposerait au choix, c'est ce qui reste quand la thermique ne peut
/// pas. Sur le parc ETEELO la NT-8003DD est **invisible du spouleur Android**,
/// faute de service d'impression constructeur — le PDF sert donc à enregistrer,
/// partager, ou sortir sur une imprimante de bureau, jamais à alimenter la
/// thermique.
///
/// ## Ce que chaque issue déclenche
///
/// * **Imprimé** — rien. Le papier est sorti.
/// * **Annulé** — rien non plus. Ouvrir le spouleur derrière serait insister là
///   où le caissier vient de renoncer.
/// * **Échec** — la cause exacte, puis le repli. Les quatre causes sont
///   distinctes parce que le geste qu'elles appellent l'est : accorder une
///   permission, allumer le Bluetooth, appairer une imprimante, rallumer la
///   machine. Un message unique ferait chercher la mauvaise panne au guichet.
///
/// Le repli reçoit le **modèle déjà composé**, jamais un `paymentId` à
/// recomposer : les deux sorties doivent rendre le même ticket, et une écriture
/// concurrente entre les deux remettrait au parent un papier qui ne dit pas ce
/// que la thermique n'a pas réussi à imprimer.
///
/// ⚠️ Rien ici n'est un échec d'encaissement : le versement est **déjà écrit
/// localement**. Tout ce qui suit ne coûte que du papier.
Future<void> printProvisionalTicketWithFallback(
  BuildContext context, {
  required String paymentId,
  required ScaffoldMessengerState? messenger,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final model = await buildProvisionalTicket(context, paymentId: paymentId);
  if (!context.mounted) return;

  if (model == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.ticketPrintFailed)));
    return;
  }

  final outcome = await printThermalTicket(context, model: model);
  if (!context.mounted) return;

  switch (outcome) {
    case ThermalTicketPrinted():
    case ThermalTicketCancelled():
      return;

    case ThermalTicketFailed(problem: final problem):
      messenger?.showSnackBar(
        SnackBar(content: Text(_problemMessage(l10n, problem))),
      );

      final printed = await printProvisionalTicket(context, model: model);
      // Le filet a lâché à son tour : le dire, plutôt que laisser le caissier
      // croire le papier parti. Un appui qui ne produit rien du tout est le
      // seul cas vraiment intenable au guichet.
      if (!printed) {
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.ticketPrintFailed)),
        );
      }
  }
}

String _problemMessage(
  AppLocalizations l10n,
  ThermalPrinterProblem problem,
) => switch (problem) {
  ThermalPrinterProblem.permissionDenied => l10n.ticketPrinterProblemPermission,
  ThermalPrinterProblem.bluetoothOff => l10n.ticketPrinterProblemBluetoothOff,
  ThermalPrinterProblem.noPrinterSelected => l10n.ticketPrinterProblemNoPrinter,
  ThermalPrinterProblem.unreachable => l10n.ticketPrinterProblemUnreachable,
};
