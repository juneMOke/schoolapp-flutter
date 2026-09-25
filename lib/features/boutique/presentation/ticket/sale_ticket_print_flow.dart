import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/resolve_ticket_copies_use_case.dart';
import 'package:school_app_flutter/features/boutique/data/ticket/sale_ticket_composer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_text_layout.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_labels_factory.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/data/ticket/pdf_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre le ticket de vente au comptoir, puis l'imprime.
///
/// ⚠️ **Rien ici n'est un échec d'encaissement.** La vente est déjà écrite
/// localement quand cette fonction s'exécute : tout ce qui suit ne coûte que du
/// papier. Un message le dit, et la vente reste à l'écran pour réessayer.
///
/// ## L'aperçu d'abord, la thermique ensuite
///
/// Le caissier voit le ticket avant qu'il ne sorte — même geste que pour un
/// registre ou un reçu scellé. L'impression reste **thermique** : le bouton du
/// pied déclenche le même envoi ESC/POS qu'auparavant, jamais le spouleur, qui
/// ne voit pas la NT-8003DD.
///
/// Les deux sorties partent des **mêmes lignes**, composées une seule fois :
/// l'aperçu ne doit pas pouvoir montrer un papier que l'imprimante ne sortira
/// pas. Le PDF se compose sur une **feuille** et non sur le rouleau — une page
/// de hauteur infinie ne se rasterise pas à l'écran.
///
/// Rend **vrai si le papier est sorti** — et rien d'autre. Un envoi annulé, une
/// imprimante absente ou un échec rendent faux : l'appelant s'en sert pour
/// noter la trace d'impression, et marquer un envoi qui a échoué ferait
/// afficher « déjà imprimé » sur un ticket que personne n'a en main.
///
/// [previewBuilder] substitue l'aperçu, et c'est la seule façon de tester ce
/// flux : le vrai `PdfPreview` rasterise par canal de plateforme, et son gabarit
/// de chargement anime en boucle — `pumpAndSettle` n'y rendrait jamais la main.
Future<bool> printSaleTicket(
  BuildContext context, {
  required RecordedSale sale,
  required Map<String, String> levelLabels,
  required ScaffoldMessengerState? messenger,
  Widget Function(BuildContext context, PrintableDocument document)?
  previewBuilder,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // Tout ce qui vient du contexte est prélevé MAINTENANT : ce qui suit doit
  // pouvoir aboutir alors que l'écran a changé.
  final labels = saleTicketLabelsOf(l10n);
  final title = l10n.boutiqueTicketDocumentTitle;
  final printedNotice = l10n.boutiqueReceiptPrinted;
  final failedNotice = l10n.boutiqueReceiptPrintFailed;

  // Le point de départ du compteur d'exemplaires : le réglage de l'école, ou
  // un — le même que pour le ticket de perception.
  final defaultCopies = await getIt<ResolveTicketCopiesUseCase>()();

  final model = await getIt<SaleTicketComposer>().compose(
    sale,
    labels: labels,
    levelLabels: levelLabels,
  );
  if (!context.mounted) return false;

  // Une seule composition, deux sorties : le papier montré est le papier tiré.
  final lines = SaleTicketTextLayout.render(model);
  final preview = await PdfTicketRenderer.renderLines(
    lines,
    format: PdfPageFormat.a4,
  );
  if (!context.mounted) return false;

  // L'issue est retenue dans la fermeture : la visionneuse ne rend rien, et
  // c'est bien l'impression — pas l'ouverture de l'aperçu — qui décide si une
  // trace doit être posée.
  var printed = false;

  await showEteeloDocumentViewer(
    context,
    title: title,
    document: PrintableDocument(bytes: preview, fileName: '$title.pdf'),
    previewBuilder: previewBuilder,
    // Le ticket est tiré : l'aperçu se referme, et le message d'échec éventuel
    // redevient atteignable — sous une modale, ses appuis seraient avalés.
    closeAfterPrint: true,
    onPrint: () async {
      final outcome = await printThermalBytes(
        context,
        bytes: EscPosTicketRenderer.renderLines(lines),
        initialCopies: defaultCopies,
      );

      switch (outcome) {
        case ThermalTicketPrinted():
          printed = true;
          messenger?.showSnackBar(SnackBar(content: Text(printedNotice)));
        // Le caissier a fermé la liste : le geste demandé a été repris.
        // Insister par un message serait lui reprocher son propre choix.
        case ThermalTicketCancelled():
          break;
        case ThermalTicketNoSurface():
        case ThermalTicketFailed():
          messenger?.showSnackBar(SnackBar(content: Text(failedNotice)));
      }
    },
  );

  return printed;
}
