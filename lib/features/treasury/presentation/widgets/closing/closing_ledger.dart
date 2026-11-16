import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Le point de la journée » (B5) : ouverture, entrées, sorties, puis le reste
/// à vérifier. Le reste affiché est [shownExpectedInCents] — celui qui part
/// avec la réponse, et que le serveur compare au sien.
class ClosingLedger extends StatelessWidget {
  final CashDaySummary summary;
  final int shownExpectedInCents;

  const ClosingLedger({
    super.key,
    required this.summary,
    required this.shownExpectedInCents,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currency = summary.register.currency;
    final accent = CurrencyTones.accent(currency.code);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              l10n.treasuryDayPoint.toUpperCase(),
              style: AppTypography.labelCaps,
            ),
          ),
          _Line(
            label: l10n.treasuryLedgerOpening,
            value: TreasuryFormat.money(summary.openingInCents, currency),
            ink: AppColors.terreCuite,
          ),
          _Line(
            label: l10n.treasuryInflows,
            count: l10n.treasuryMovesCount(summary.inflowsCount),
            value: TreasuryFormat.signedMoney(summary.inflowsInCents, currency),
            ink: AppColors.success,
          ),
          _Line(
            label: l10n.treasuryOutflows,
            count: l10n.treasuryMovesCount(summary.outflowsCount),
            value: TreasuryFormat.signedMoney(
              -summary.outflowsInCents,
              currency,
            ),
            ink: AppColors.error,
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              border: const Border(
                top: BorderSide(color: AppColors.bleuProfond, width: 2),
              ),
            ),
            // Le reste ne se coupe jamais : sur un téléphone en gros texte, il
            // passe sous son libellé plutôt que de déborder — c'est le
            // chiffre que la caissière compare à ses billets.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.treasuryRemaining,
                      style: AppTypography.titleSmall,
                    ),
                    Text(
                      l10n.treasuryLedgerFormula,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  TreasuryFormat.money(shownExpectedInCents, currency),
                  softWrap: false,
                  style: AppTextStyles.totalAmountLora.copyWith(color: accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String? count;
  final String value;
  final Color ink;

  const _Line({
    required this.label,
    required this.value,
    required this.ink,
    this.count,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs + 2,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label, style: AppTypography.bodyMedium),
                if (count != null)
                  TextSpan(
                    text: '  $count',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          softWrap: false,
          style: AppTextStyles.moneyTabular.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
