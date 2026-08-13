import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/documents/presentation/ticket/provisional_ticket_print_flow.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rattrapage d'un ticket qui n'est jamais sorti.
///
/// ## Ce que ce n'est pas
///
/// **Pas une réimpression.** ADR-013 l'interdit en V1, et pour une raison qui
/// tient toujours : deux papiers indiscernables pour un même versement peuvent
/// être remis à deux personnes. Ici le versement n'a JAMAIS été servi — la
/// tablette le sait, parce qu'un tirage thermique réussi laisse une trace —, et
/// la ligne disparaît dès qu'un papier sort. Le geste ne peut pas être répété.
///
/// ## Pourquoi dans le corps et pas au pied de la modale
///
/// Le pied n'a que deux places, prises par « Télécharger le reçu » et
/// « Fermer », et les élargir toucherait ses cinq appelants. Surtout, un bouton
/// de pied qui n'apparaît que parfois ne dit pas POURQUOI il est là : cette
/// ligne porte l'information — le ticket n'est pas sorti — et l'action qui la
/// résout, dans le même bloc.
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
    // On relit plutôt que de supposer : un repli PDF laisse le rattrapage
    // ouvert, puisqu'il ne prouve pas qu'un papier soit sorti.
    await status.load(widget.paymentId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            child: Text(
              l10n.facturationPaymentTicketNotPrinted,
              style: AppTextStyles.body,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: _printing ? null : _print,
            child: Text(l10n.facturationPaymentPrintTicketAction),
          ),
        ],
      ),
    );
  }
}
