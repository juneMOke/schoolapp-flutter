import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_modal_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_ticket_print_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le pied du détail d'un versement.
///
/// **Imprimer le ticket est le geste principal** quand un ticket est offert :
/// au guichet, c'est ce que le parent attend — un papier. Il occupe la place
/// qu'avait « Fermer » ; la croix de l'en-tête ferme toujours la fiche.
/// « Télécharger le reçu » reste en secondaire.
///
/// Sans ticket offert (reçu retiré, versement annulé), le pied redevient
/// « Télécharger le reçu » / « Fermer ».
class FacturationPaymentDetailFooter extends StatefulWidget {
  /// Le versement dont le ticket s'imprime, `null` quand aucun ticket n'est
  /// offert.
  final String? ticketPaymentId;

  final VoidCallback? onDownloadReceipt;
  final String? downloadHint;
  final VoidCallback onClose;

  const FacturationPaymentDetailFooter({
    super.key,
    required this.ticketPaymentId,
    required this.onDownloadReceipt,
    required this.onClose,
    this.downloadHint,
  });

  @override
  State<FacturationPaymentDetailFooter> createState() =>
      _FacturationPaymentDetailFooterState();
}

class _FacturationPaymentDetailFooterState
    extends State<FacturationPaymentDetailFooter>
    with TicketPrintGesture {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paymentId = widget.ticketPaymentId;
    // `watch` seulement quand un ticket est offert : c'est alors, et alors
    // seulement, que le libellé dépend du dernier tirage.
    final printed =
        paymentId != null &&
        context.watch<TicketPrintStatusCubit>().state.wasPrinted;

    return FinanceModalFooter(
      secondaryLabel: l10n.facturationPaymentDownloadReceiptLabel,
      secondaryIcon: Icons.download_outlined,
      onSecondary: widget.onDownloadReceipt,
      secondaryHint: widget.downloadHint,
      primaryLabel: paymentId == null
          ? l10n.facturationPaymentCloseLabel
          : printed
          ? l10n.facturationPaymentReprintTicketAction
          : l10n.facturationPaymentPrintTicketPrimary,
      primaryIcon: paymentId == null
          ? Icons.check_rounded
          : Icons.print_outlined,
      onPrimary: paymentId == null
          ? widget.onClose
          : printing
          ? null
          : () => printTicket(paymentId),
    );
  }
}
