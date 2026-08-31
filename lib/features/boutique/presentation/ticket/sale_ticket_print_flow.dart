import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/boutique/data/ticket/sale_ticket_composer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/features/boutique/domain/ticket/sale_ticket_text_layout.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_labels_factory.dart';
import 'package:school_app_flutter/features/documents/data/ticket/esc_pos_ticket_renderer.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_outcome.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/thermal_ticket_printer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Imprime le ticket de vente au comptoir.
///
/// ⚠️ **Rien ici n'est un échec d'encaissement.** La vente est déjà écrite
/// localement quand cette fonction s'exécute : tout ce qui suit ne coûte que du
/// papier. Un message le dit, et la vente reste à l'écran pour réessayer.
///
/// La composition est faite **avant** d'ouvrir la moindre boîte de dialogue :
/// l'envoi thermique peut rester en vol une trentaine de secondes, et un
/// caissier qui referme pour servir le client suivant ne doit pas perdre son
/// ticket.
/// Rend **vrai si le papier est sorti** — et rien d'autre. Un envoi annulé, une
/// imprimante absente ou un échec rendent faux : l'appelant s'en sert pour
/// noter la trace d'impression, et marquer un envoi qui a échoué ferait
/// afficher « déjà imprimé » sur un ticket que personne n'a en main.
Future<bool> printSaleTicket(
  BuildContext context, {
  required RecordedSale sale,
  required Map<String, String> levelLabels,
  required ScaffoldMessengerState? messenger,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // Tout ce qui vient du contexte est prélevé MAINTENANT : ce qui suit doit
  // pouvoir aboutir alors que l'écran a changé.
  final labels = saleTicketLabelsOf(l10n);
  final printedNotice = l10n.boutiqueReceiptPrinted;
  final failedNotice = l10n.boutiqueReceiptPrintFailed;

  final model = await getIt<SaleTicketComposer>().compose(
    sale,
    labels: labels,
    levelLabels: levelLabels,
  );
  if (!context.mounted) return false;

  final bytes = EscPosTicketRenderer.renderLines(
    SaleTicketTextLayout.render(model),
  );
  final outcome = await printThermalBytes(context, bytes: bytes);

  switch (outcome) {
    case ThermalTicketPrinted():
      messenger?.showSnackBar(SnackBar(content: Text(printedNotice)));
      return true;
    // Le caissier a fermé la liste : le geste demandé a été repris. Insister
    // par un message serait lui reprocher son propre choix.
    case ThermalTicketCancelled():
      return false;
    case ThermalTicketNoSurface():
    case ThermalTicketFailed():
      messenger?.showSnackBar(SnackBar(content: Text(failedNotice)));
      return false;
  }
}
