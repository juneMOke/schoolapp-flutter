import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_local_models.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le contenu figé d'une vente : ce que le client est reparti avec.
///
/// Les libellés et les prix viennent de la vente, **jamais du catalogue** : le
/// catalogue est remplacé en bloc à chaque bundle (invariant I-6), et une vente
/// d'hier doit rester lisible après le retrait de l'article qu'elle porte.
class BoutiqueSaleDetailLines extends StatelessWidget {
  final List<BoutiqueSaleLineLocalModel> lines;

  const BoutiqueSaleDetailLines({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
          _LineRow(line: lines[i]),
        ],
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final BoutiqueSaleLineLocalModel line;

  const _LineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final meta = [
      l10n.boutiqueLineMeta(
        BoutiqueMoneyFormat.compact(line.unitPriceInCents, line.currency),
        line.quantity,
      ),
      if ((line.size ?? '').trim().isNotEmpty)
        l10n.boutiqueSaleDetailSizePrefix(line.size!),
      // Le bénéficiaire figé sur la ligne, jamais rejoint à la fiche élève : un
      // élève réinscrit ailleurs ne doit pas réécrire une vente d'hier.
      if ((line.beneficiaryName ?? '').trim().isNotEmpty)
        l10n.boutiqueSaleDetailBeneficiary(line.beneficiaryName!),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.terreCuite.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${line.quantity}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.terreCuite,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.articleLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.bleuProfond,
                  ),
                ),
                Text(
                  meta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            BoutiqueMoneyFormat.exact(line.lineTotalInCents, line.currency),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.bleuProfond,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
