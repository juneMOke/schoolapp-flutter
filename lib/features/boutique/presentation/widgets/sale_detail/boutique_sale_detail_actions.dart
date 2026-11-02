import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de la fiche : le ticket, le reçu scellé, sa réclamation.
class BoutiqueSaleDetailActions extends StatelessWidget {
  final SaleDetail detail;
  final bool isPrinting;
  final bool isClaiming;
  final VoidCallback onPrintTicket;
  final VoidCallback onOpenReceipt;
  final VoidCallback onClaimReceipt;

  const BoutiqueSaleDetailActions({
    super.key,
    required this.detail,
    required this.isPrinting,
    required this.isClaiming,
    required this.onPrintTicket,
    required this.onOpenReceipt,
    required this.onClaimReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isPrinting ? null : onPrintTicket,
          icon: isPrinting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined, size: 20),
          // Le libellé dit LEQUEL des deux gestes on fait : sortir un ticket
          // qui n'existe pas encore, ou en refaire un.
          label: Text(
            detail.ticketWasPrinted
                ? l10n.boutiqueSaleDetailReprintTicket
                : l10n.boutiqueSaleDetailPrintTicket,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.terreCuite,
            // ⚠️ Sans `minimumSize`, un bouton inline hérite du thème
            // plein-largeur et lève en contrainte infinie.
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          detail.ticketPrintedAt == null
              ? l10n.boutiqueSaleDetailTicketNeverPrinted
              : l10n.boutiqueSaleDetailTicketPrintedAt(
                  formatSchoolDateTime(detail.ticketPrintedAt!),
                ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMutedAa,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // Le reçu scellé n'existe que si le serveur l'a produit. Offrir le
        // bouton avant ferait ouvrir une pièce introuvable : la phrase dit ce
        // qu'on attend, et quand.
        if (detail.hasSealedReceipt)
          OutlinedButton.icon(
            onPressed: onOpenReceipt,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            label: Text(l10n.boutiqueSaleDetailOpenReceipt),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          )
        else
          BoutiqueSaleNotice(
            icon: Icons.schedule_outlined,
            color: AppColors.textMutedAa,
            text: l10n.boutiqueSaleDetailReceiptPending,
          ),
        // **Réclamer, et non émettre.** Le serveur scelle la pièce au push de la
        // vente, mais son scellement est *best-effort* : sans ce geste, une
        // vente dont l'ACK est revenu sans document attend un pull qui
        // n'apportera jamais son numéro. Le serveur journalise lui-même qu'il
        // compte sur cet appel.
        //
        // Deux manques le déclenchent, et le second mérite sa phrase : une pièce
        // scellée dont le NUMÉRO est inconnu s'ouvre très bien tout en laissant
        // la ligne « Reçu » afficher une référence provisoire, indéfiniment.
        if (detail.canClaimReceipt) ...[
          if (detail.hasSealedReceipt) ...[
            const SizedBox(height: AppDimensions.spacingS),
            BoutiqueSaleNotice(
              icon: Icons.pin_outlined,
              color: AppColors.warningInk,
              text: l10n.boutiqueSaleDetailReceiptNumberMissing,
            ),
          ],
          const SizedBox(height: AppDimensions.spacingS),
          // La route exige `boutique.sale.write` ET `editique.write`. La garde
          // est prise au registre plutôt qu'écrite ici : recopiée, elle
          // finirait par diverger — et sans sa conjonction, le porteur d'une
          // seule des deux permissions verrait la porte pour prendre un 403.
          PermissionGate.access(
            kBoutiqueCollectAccess,
            child: OutlinedButton.icon(
              onPressed: isClaiming ? null : onClaimReceipt,
              icon: isClaiming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download_outlined, size: 20),
              label: Text(l10n.boutiqueSaleDetailClaimReceipt),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Un avis dans la teinte de [color] : celle-ci écrit le texte, elle doit
/// donc être une ENCRE (≥ 4,5:1 sur son propre voile) — `warningInk`, jamais
/// `warning` (2,5:1).
class BoutiqueSaleNotice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const BoutiqueSaleNotice({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppDimensions.spacingM),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.24)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, height: 1.35),
          ),
        ),
      ],
    ),
  );
}
