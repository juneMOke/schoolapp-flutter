import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/recorded_sale.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';

/// Ce que le guichet voit une fois la vente écrite : elle est encaissée, et le
/// seul geste qui reste est de remettre le ticket.
///
/// **Fermer vaut terminer.** La croix, le fond et « Terminer » ont exactement la
/// même issue — panier vidé, retour au catalogue. Un chemin qui laisserait la
/// vente encaissée à l'écran ferait recomposer la suivante par-dessus.
///
/// Le sous-titre dit **lequel des deux documents** le porteur tient : un ticket
/// provisoire et un reçu scellé se ressemblent au comptoir, et c'est le seul
/// endroit où l'écran peut lever le doute.
class BoutiqueSaleSuccessDialog extends StatefulWidget {
  final RecordedSale sale;

  /// Imprime le ticket. **Aucun échec ici n'est un échec d'encaissement** : la
  /// vente est déjà écrite, et le papier ne coûte que du papier.
  final Future<void> Function() onPrint;

  const BoutiqueSaleSuccessDialog({
    super.key,
    required this.sale,
    required this.onPrint,
  });

  static Future<void> show(
    BuildContext context, {
    required RecordedSale sale,
    required Future<void> Function() onPrint,
  }) => showDialog<void>(
    context: context,
    builder: (_) => BoutiqueSaleSuccessDialog(sale: sale, onPrint: onPrint),
  );

  @override
  State<BoutiqueSaleSuccessDialog> createState() =>
      _BoutiqueSaleSuccessDialogState();
}

class _BoutiqueSaleSuccessDialogState extends State<BoutiqueSaleSuccessDialog> {
  /// Vrai pendant l'envoi à l'imprimante — le bouton se neutralise plutôt que
  /// de laisser empiler deux envois vers la même machine.
  bool _isPrinting = false;

  Future<void> _print() async {
    setState(() => _isPrinting = true);
    try {
      await widget.onPrint();
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sale = widget.sale;
    final total = sale.lines.totals.entries.map(MoneyFormat.format).join(' · ');
    final receiptNumber = sale.sale.receiptNumber;
    final sealed = receiptNumber != null;

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: EteeloDialogBody(
          header: EteeloDialogDarkHeader(
            eyebrow: l10n.boutiqueSuccessEyebrow,
            title: l10n.boutiqueSuccessTitle,
            onClose: () => Navigator.of(context).pop(),
          ),
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // La coche verte, franche : c'est le seul écran de la caisse qui
              // annonce que c'est fini, et il doit se lire de loin — le guichet
              // regarde déjà le client suivant.
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.vertSavane.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.vertSavane.withValues(alpha: 0.30),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 34,
                    color: AppColors.vertSavane,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                total,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.bleuProfond,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                l10n.boutiqueSuccessMessage(total),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              // Le sous-titre dit LEQUEL des deux documents le porteur tient :
              // un ticket provisoire et un reçu scellé se ressemblent au
              // comptoir, et c'est le seul endroit où l'écran lève le doute.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                decoration: BoxDecoration(
                  color: sealed
                      ? AppColors.vertSavane.withValues(alpha: 0.06)
                      : AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sealed
                        ? AppColors.vertSavane.withValues(alpha: 0.25)
                        : AppColors.warning.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sealed
                          ? Icons.verified_outlined
                          : Icons.schedule_outlined,
                      size: 16,
                      color: sealed ? AppColors.vertSavane : AppColors.warning,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        sealed
                            ? l10n.boutiqueReceiptBannerSealed(receiptNumber)
                            : l10n.boutiqueReceiptBannerProvisional(
                                ProvisionalSaleReference.of(sale.id),
                              ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: sealed
                              ? AppColors.vertSavane
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          footer: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _isPrinting ? null : _print,
                      icon: _isPrinting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print_outlined, size: 18),
                      label: Text(l10n.boutiqueReceiptPrint),
                      style: OutlinedButton.styleFrom(
                        // ⚠️ Sans `minimumSize`, un bouton inline hérite du
                        // thème plein-largeur et lève en contrainte infinie.
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.terreCuite,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.boutiqueSuccessDone),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
