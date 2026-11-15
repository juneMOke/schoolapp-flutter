import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le montant actuel, et dès que la saisie en diffère : l'ancien barré, le
/// nouveau, et l'écart signé (« Ajustement de +80,00 $ »). Le signe et la
/// flèche disent le sens, la couleur ne le dit jamais seule.
class AdjustAmountSummary extends StatelessWidget {
  final TreasuryCurrency currency;
  final int currentInCents;
  final int? newAmountInCents;

  const AdjustAmountSummary({
    super.key,
    required this.currency,
    required this.currentInCents,
    required this.newAmountInCents,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = newAmountInCents;
    final changed = next != null && next != currentInCents;
    final accent = CurrencyTones.accent(currency.code);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: AppRadius.brMd,
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Figure(
                label: l10n.treasuryAdjustCurrent,
                value: TreasuryFormat.money(currentInCents, currency),
                color: accent,
                struck: changed,
              ),
              if (changed) ...[
                Icon(Icons.arrow_forward, color: accent),
                _Figure(
                  label: l10n.treasuryAdjustAfter,
                  value: TreasuryFormat.money(next, currency),
                  color: accent,
                ),
              ],
            ],
          ),
        ),
        if (changed) ...[
          const SizedBox(height: AppSpacing.sm),
          _DeltaBanner(delta: next - currentInCents, currency: currency),
        ],
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool struck;

  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    this.struck = false,
  });

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: struck ? 0.55 : 1,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(color: color),
        ),
        Text(
          value,
          softWrap: false,
          style: AppTextStyles.totalAmountLora.copyWith(
            color: AppColors.bleuProfond,
            decoration: struck ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    ),
  );
}

class _DeltaBanner extends StatelessWidget {
  final int delta;
  final TreasuryCurrency currency;

  const _DeltaBanner({required this.delta, required this.currency});

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final color = up ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        children: [
          Icon(up ? Icons.trending_up : Icons.trending_down, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.treasuryAdjustDelta(
                TreasuryFormat.signedMoney(delta, currency),
              ),
              style: AppTypography.labelLarge.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
