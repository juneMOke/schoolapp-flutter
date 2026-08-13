import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/data/printing/thermal_printer_permission.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
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
  // Tout ce qui vient du contexte est prélevé MAINTENANT. Ce qui suit doit
  // pouvoir aboutir alors que la modale a disparu : l'envoi thermique peut
  // rester en vol une trentaine de secondes (15 s de connexion + 20 s
  // d'écriture), sans indicateur à l'écran, et un caissier qui referme pour
  // servir le parent suivant ne doit pas perdre le ticket d'un versement déjà
  // encaissé — il n'existe aucun chemin de réimpression.
  final cutNotice = l10n.ticketCutNotice;

  final model = await buildProvisionalTicket(context, paymentId: paymentId);

  if (model == null) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.ticketPrintFailed)));
    return;
  }

  // Même raison qu'au-dessus, un cran plus tôt : sans surface, on ne peut plus
  // demander l'imprimante, mais on peut encore remettre un papier.
  if (!context.mounted) {
    await printProvisionalTicket(model: model, cutNotice: cutNotice);
    return;
  }

  final outcome = await printThermalTicket(context, model: model);

  switch (outcome) {
    // Le seul signal qui prouve qu'un papier existe. On le retient ici, et
    // nulle part ailleurs : c'est lui qui retirera le rattrapage d'impression
    // du détail de ce versement.
    case ThermalTicketPrinted():
      await getIt<MarkTicketPrintedUseCase>()(paymentId);
      return;

    case ThermalTicketCancelled():
      return;

    // Personne n'a renoncé : la modale s'est fermée pendant la préparation.
    // Le repli, silencieux — il n'y a aucune cause à annoncer, et plus d'écran
    // pour la lire.
    case ThermalTicketNoSurface():
      await printProvisionalTicket(model: model, cutNotice: cutNotice);

    case ThermalTicketFailed(problem: final problem):
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_problemMessage(l10n, problem)),
          // Une permission refusée définitivement ne se redemande plus : Android
          // ne réaffiche jamais la boîte de dialogue, et sans ce raccourci le
          // caissier n'a plus aucun chemin vers les réglages depuis
          // l'application. L'action est portée par le message plutôt que
          // déclenchée d'office : le papier passe d'abord, la maintenance
          // ensuite — basculer sur les réglages ferait sortir le spouleur
          // derrière une application passée en arrière-plan.
          action: problem == ThermalPrinterProblem.permissionDenied
              ? SnackBarAction(
                  label: l10n.settings,
                  onPressed: () =>
                      getIt<ThermalPrinterPermission>().openSettings(),
                )
              : null,
        ),
      );

      // Le messenger vient du `ScaffoldMessenger` de l'application, jamais
      // démonté : il a été capturé avant le premier await précisément pour
      // survivre à la modale. Le spouleur, lui, n'a besoin d'aucun widget.
      final printed = await printProvisionalTicket(
        model: model,
        cutNotice: cutNotice,
      );
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
