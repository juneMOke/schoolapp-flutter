import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/sale_receipt_watch_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_receipt_banner.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
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
/// Le ticket ne sort qu'avec le **numéro définitif** du reçu : le bandeau dit
/// qu'il se scelle, puis le numéro dès qu'il arrive, et « Imprimer » ne s'offre
/// qu'à ce moment-là. Faute de numéro dans le délai, le ticket s'imprimera
/// depuis la fiche de la vente.
class BoutiqueSaleSuccessDialog extends StatefulWidget {
  final RecordedSale sale;

  /// Guette le numéro du reçu. Créé et refermé par l'appelant.
  final SaleReceiptWatchCubit watch;

  /// Imprime le ticket de la vente telle que relue — celle qui porte le
  /// numéro. **Aucun échec ici n'est un échec d'encaissement** : la vente est
  /// déjà écrite, et le papier ne coûte que du papier.
  final Future<void> Function(RecordedSale sale) onPrint;

  const BoutiqueSaleSuccessDialog({
    super.key,
    required this.sale,
    required this.watch,
    required this.onPrint,
  });

  static Future<void> show(
    BuildContext context, {
    required RecordedSale sale,
    required SaleReceiptWatchCubit watch,
    required Future<void> Function(RecordedSale sale) onPrint,
  }) => showDialog<void>(
    context: context,
    builder: (_) =>
        BoutiqueSaleSuccessDialog(sale: sale, watch: watch, onPrint: onPrint),
  );

  @override
  State<BoutiqueSaleSuccessDialog> createState() =>
      _BoutiqueSaleSuccessDialogState();
}

class _BoutiqueSaleSuccessDialogState extends State<BoutiqueSaleSuccessDialog> {
  /// Vrai pendant l'envoi à l'imprimante — le bouton se neutralise plutôt que
  /// de laisser empiler deux envois vers la même machine.
  bool _isPrinting = false;

  Future<void> _print(RecordedSale sale) async {
    setState(() => _isPrinting = true);
    try {
      await widget.onPrint(sale);
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
    return BlocBuilder<SaleReceiptWatchCubit, SaleReceiptWatchState>(
      bloc: widget.watch,
      builder: (context, watch) => _dialog(context, l10n, theme, total, watch),
    );
  }

  Widget _dialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String total,
    SaleReceiptWatchState watch,
  ) {
    final numbered = watch.phase == SaleReceiptPhase.numbered
        ? watch.sale
        : null;
    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.boutiqueDialogMaxWidth,
        ),
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
              BoutiqueSaleReceiptBanner(watch: watch),
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
                      // Pas de numéro, pas de ticket : le bouton attend le
                      // reçu scellé, comme au guichet de perception.
                      onPressed: _isPrinting || numbered == null
                          ? null
                          : () => _print(numbered),
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
