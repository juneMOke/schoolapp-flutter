import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Compose puis remet à l'impression le reçu provisoire d'un encaissement.
///
/// C'est l'exigence terrain irréductible de l'ADR-012 : un parent qui verse des
/// espèces repart **avec un papier**, coupure réseau ou non. Rien ici ne touche
/// le réseau.
///
/// ## Le format vient du spouleur, il n'est pas imposé (AM-11)
///
/// `Printing.layoutPdf` remet le document au spouleur système, qui applique le
/// **papier choisi par l'utilisateur**. Lui remettre une page `roll80` sur un
/// poste sans imprimante thermique la faisait ressortir étirée sur A4 : un repli
/// étiré n'est pas un repli.
///
/// Le ticket est donc composé **pour le format que le spouleur annonce**
/// (`onLayout` reçoit le média réellement sélectionné, marges de zone imprimable
/// comprises) : bloc de 80 mm à l'échelle 1 sur une feuille de bureau, largeur
/// du rouleau respectée si une thermique est sélectionnée. `PdfPageFormat.a4`
/// n'est que la proposition initiale de la boîte de dialogue.
///
/// Renvoie `false` si rien n'a pu être produit ou remis au spouleur ; l'appelant
/// est responsable de le dire à l'utilisateur, jamais d'échouer en silence.
/// Compose le ticket du versement [paymentId], ou `null` s'il est introuvable.
///
/// Séparé de l'impression depuis que le ticket a **deux sorties possibles** :
/// la thermique d'abord, ce PDF en filet. Les deux doivent rendre le **même**
/// ticket — un repli qui recomposerait le sien pourrait, à la faveur d'une
/// écriture concurrente, remettre au parent un papier qui ne dit pas ce que la
/// thermique n'a pas réussi à imprimer.
Future<TicketReceiptModel?> buildProvisionalTicket(
  BuildContext context, {
  required String paymentId,
}) async {
  final labels = provisionalTicketLabels(AppLocalizations.of(context)!);

  final built = await getIt<BuildProvisionalTicketUseCase>()(
    paymentId: paymentId,
    labels: labels,
  );

  return built.fold((_) => null, (model) => model);
}

Future<bool> printProvisionalTicket(
  BuildContext context, {
  required TicketReceiptModel model,
}) async {
  final cutNotice = AppLocalizations.of(context)!.ticketCutNotice;

  {
    try {
      // Rendu de référence produit AVANT de solliciter le spouleur : une
      // composition impossible se dit tout de suite, plutôt qu'après avoir
      // ouvert une boîte de dialogue d'impression qui se refermera seule.
      final fallback = await PdfTicketRenderer.render(
        model,
        format: _initialFormat,
        cutNotice: cutNotice,
      );

      await Printing.layoutPdf(
        onLayout: (format) async {
          try {
            return await PdfTicketRenderer.render(
              model,
              format: format,
              cutNotice: cutNotice,
            );
          } catch (_) {
            // Média annoncé trop exigu pour composer le bloc : mieux vaut le
            // ticket de référence, juste mais peut-être mis à l'échelle, que
            // pas de ticket du tout — le repli est le filet, il ne doit pas
            // casser à son tour. Sans cette reprise, l'exception annulerait
            // toute la tâche d'impression.
            return fallback;
          }
        },
        name: model.provisionalReference,
        format: _initialFormat,
      );
      return true;
    } catch (_) {
      // Canal de plateforme absent, service d'impression indisponible : la
      // pièce est intacte, seul le geste a échoué.
      return false;
    }
  }
}

/// Proposition initiale de la boîte de dialogue — jamais une contrainte : c'est
/// le média annoncé par `onLayout` qui décide de la composition. A4 est le
/// papier de bureau par défaut de la cible.
const PdfPageFormat _initialFormat = PdfPageFormat.a4;
