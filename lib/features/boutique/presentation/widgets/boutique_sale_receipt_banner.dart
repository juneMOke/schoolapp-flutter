import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/sale_receipt_watch_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Où en est le reçu de la vente qui vient d'être encaissée.
///
/// Le ticket ne sort qu'avec le numéro définitif : ce bandeau dit au guichet
/// pourquoi « Imprimer » attend — le reçu se scelle —, puis le numéro dès qu'il
/// arrive, ou que le ticket attendra la synchronisation.
class BoutiqueSaleReceiptBanner extends StatelessWidget {
  final SaleReceiptWatchState watch;

  const BoutiqueSaleReceiptBanner({super.key, required this.watch});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final number = watch.receiptNumber;
    final sealed = watch.phase == SaleReceiptPhase.numbered && number != null;
    final tone = sealed ? AppColors.vertSavane : AppColors.warning;
    final message = switch (watch.phase) {
      SaleReceiptPhase.numbered when number != null =>
        l10n.boutiqueReceiptBannerSealed(number),
      SaleReceiptPhase.deferred => l10n.boutiqueReceiptBannerDeferred,
      _ => l10n.boutiqueReceiptBannerAwaiting,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: sealed ? 0.06 : 0.08),
        borderRadius: AppRadius.brSm,
        border: Border.all(color: tone.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            switch (watch.phase) {
              SaleReceiptPhase.numbered => Icons.verified_outlined,
              SaleReceiptPhase.deferred => Icons.schedule_outlined,
              // Une icône fixe, pas un indicateur animé : l'attente dure
              // quelques secondes et l'animation ne dirait rien de plus.
              _ => Icons.hourglass_top_rounded,
            },
            size: AppDimensions.boutiqueReceiptBannerIcon,
            color: tone,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
