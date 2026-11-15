import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_period.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une caisse sur la semaine ou le mois (B7) : le reste en fin de période,
/// puis l'ouverture (veille du premier jour), les entrées, les sorties et, s'il
/// y en a, les écarts — ouverture + entrées − sorties + écarts = reste.
class PeriodTotalsCard extends StatelessWidget {
  final PeriodRegisterTotals totals;

  const PeriodTotalsCard({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = totals.register;
    final currency = register.currency;
    final s = totals.synthesis;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: DashboardTones.paveShadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              color: CurrencyTones.pave(currency.code),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: DashboardTones.inkValeur,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          register.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.eyebrow.copyWith(
                            color: AppColors.orDoux,
                          ),
                        ),
                        Text(
                          l10n.treasuryPeriodClosing,
                          style: AppTypography.labelSmall.copyWith(
                            color: DashboardTones.inkSousLigne,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        TreasuryFormat.money(s.closingInCents, currency),
                        softWrap: false,
                        style: AppTextStyles.moneyTabular.copyWith(
                          color: DashboardTones.inkValeur,
                          fontWeight: FontWeight.w800,
                          fontSize: AppDimensions.treasuryPeriodTotalSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _Figure(
                    label: l10n.treasuryOpening,
                    value: TreasuryFormat.money(s.openingInCents, currency),
                    ink: AppColors.terreCuite,
                  ),
                  _Figure(
                    label: l10n.treasuryInflows,
                    value: TreasuryFormat.signedMoney(
                      s.inflowsInCents,
                      currency,
                    ),
                    ink: AppColors.success,
                  ),
                  _Figure(
                    label: l10n.treasuryOutflows,
                    value: TreasuryFormat.signedMoney(
                      -s.outflowsInCents,
                      currency,
                    ),
                    ink: AppColors.error,
                  ),
                  // R17 : les écarts sur leur propre ligne, jamais dans les
                  // entrées ni les sorties — sans eux la somme ne tombe pas.
                  if (s.gapsInCents != 0)
                    _Figure(
                      label: l10n.treasuryGapTag,
                      value: TreasuryFormat.signedMoney(
                        s.gapsInCents,
                        currency,
                      ),
                      ink: AppColors.error,
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

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color ink;

  const _Figure({required this.label, required this.value, required this.ink});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        style: AppTypography.labelCaps.copyWith(color: ink),
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
  );
}
