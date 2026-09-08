import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le ticket d'un encaissement : le sortir, ou le refaire.
///
/// ## La réimpression est libre
///
/// Le bouton est **toujours offert**, sur le patron de
/// `boutique_sale_detail_page.dart`. C'est ce que le porteur a tranché, et le
/// terrain lui donne raison : un ticket se déchire, se mouille, part avec le
/// mauvais parent. Une tablette qui refuse de refaire le papier qu'elle vient
/// d'imprimer renvoie une famille au guichet le lendemain.
///
/// L'ADR-013 interdisait la réimpression en V1 pour une raison réelle — deux
/// papiers indiscernables peuvent être remis à deux personnes. La réponse n'est
/// pas de refuser le geste mais de le **dater** : la ligne dit quand le dernier
/// papier est sorti, et le bouton dit lequel des deux gestes on fait.
///
/// Une seule chose reste interdite, et elle se juge à l'écran d'à côté : un
/// **reçu annulé** ne ressort jamais en ticket.
///
/// ## Pourquoi dans le corps et pas au pied de la modale
///
/// Le pied n'a que deux places, prises par « Télécharger le reçu » et
/// « Fermer », et les élargir toucherait ses cinq appelants. Surtout, un bouton
/// de pied ne dirait pas POURQUOI il est là : cette ligne porte l'état du
/// papier et l'action qui le change, dans le même bloc.
class FacturationTicketPrintRow extends StatefulWidget {
  final String paymentId;

  const FacturationTicketPrintRow({super.key, required this.paymentId});

  @override
  State<FacturationTicketPrintRow> createState() =>
      _FacturationTicketPrintRowState();
}

class _FacturationTicketPrintRowState extends State<FacturationTicketPrintRow> {
  /// Verrou « un seul geste en vol », comme la popin d'encaissement : composer
  /// puis ouvrir l'interface système ne rend pas la main tout de suite, et deux
  /// appuis produiraient deux tickets pour un versement.
  bool _printing = false;

  Future<void> _print() async {
    if (_printing) return;

    // Capturés AVANT tout await : le premier survit à la fermeture de la
    // modale, le second ne doit plus être touché après.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final status = context.read<TicketPrintStatusCubit>();

    setState(() => _printing = true);
    await printProvisionalTicketWithFallback(
      context,
      paymentId: widget.paymentId,
      messenger: messenger,
    );
    if (!mounted) return;

    setState(() => _printing = false);
    // Le flux a marqué la trace si — et seulement si — la thermique a servi.
    // On relit plutôt que de supposer : un repli PDF ne prouve pas qu'un papier
    // soit sorti, et la ligne continue donc d'annoncer un premier tirage.
    await status.load(widget.paymentId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // `watch` et non `read` : le libellé et la mention CHANGENT après un tirage
    // réussi, puisque `_print` relit la trace. Sans reconstruction, le caissier
    // qui vient d'imprimer lirait encore « Jamais imprimé ».
    final status = context.watch<TicketPrintStatusCubit>().state;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: AppDimensions.financeRowIconSize,
            color: AppColors.bleuArdoise,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            // La mention dit l'ÉTAT, pas la consigne : « Imprimé le … » est la
            // dernière impression connue de cette tablette, réécrite à chaque
            // tirage. Une tablette qui n'a rien imprimé le dit sans prétendre
            // savoir ce qu'ont fait les autres.
            child: Text(
              status.printedAt == null
                  ? l10n.facturationPaymentTicketNotPrinted
                  : l10n.facturationPaymentTicketPrintedAt(
                      formatLocalDateTime(status.printedAt!),
                    ),
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Le libellé dit LEQUEL des deux gestes on fait : sortir un papier
          // qui n'existe pas encore, ou en refaire un.
          TextButton(
            onPressed: _printing ? null : _print,
            child: Text(
              status.wasPrinted
                  ? l10n.facturationPaymentReprintTicketAction
                  : l10n.facturationPaymentPrintTicketAction,
            ),
          ),
        ],
      ),
    );
  }
}
