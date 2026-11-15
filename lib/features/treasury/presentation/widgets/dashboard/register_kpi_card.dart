import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/balance_sparkline.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une caisse sur le tableau de bord (A2) : ce qu'elle détient, ce qui a
/// bougé depuis la clôture d'hier, ses 8 derniers jours. Toute la carte ouvre
/// la clôture de la caisse, journée du jour.
class RegisterKpiCard extends StatelessWidget {
  final RegisterOverview overview;
  final VoidCallback? onOpen;

  const RegisterKpiCard({super.key, required this.overview, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = overview.register;
    final currency = register.currency;
    final closure = overview.todayClosure;
    final closed = closure != null && closure.locksRegister;
    final delta = overview.deltaTodayInCents;
    final open = onOpen;
    return Material(
      color: CurrencyTones.pave(currency.code),
      borderRadius: AppRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        closed ? Icons.lock_outline : Icons.payments_outlined,
                        color: DashboardTones.inkValeur,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
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
                              TreasuryFormat.currencyName(l10n, currency),
                              style: AppTypography.labelSmall.copyWith(
                                color: DashboardTones.inkSousLigne,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _Pill(
                    icon: closed ? Icons.lock_outline : Icons.schedule,
                    label: closed
                        ? l10n.treasuryKpiClosedAt(
                            TreasuryFormat.time(closure.closedAt),
                          )
                        : l10n.treasuryKpiToClose,
                    ink: closed
                        ? AppColors.paveInkPercu
                        : AppColors.paveInkAttendu,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  TreasuryFormat.money(overview.balanceInCents, currency),
                  softWrap: false,
                  style: AppTextStyles.moneyTabular.copyWith(
                    color: DashboardTones.inkValeur,
                    fontWeight: FontWeight.w700,
                    fontSize: AppDimensions.treasuryKpiAmountSize,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  _Pill(
                    icon: delta < 0 ? Icons.trending_down : Icons.trending_up,
                    label:
                        '${TreasuryFormat.signedMoney(delta, currency)} '
                        '${l10n.treasuryKpiToday}',
                    ink: delta < 0
                        ? AppColors.paveInkReste
                        : AppColors.paveInkPercu,
                  ),
                  if (overview.last8Days.length > 1)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        BalanceSparkline(
                          days: overview.last8Days,
                          size: const Size(
                            AppDimensions.treasurySparklineWidth,
                            AppDimensions.treasurySparklineHeight,
                          ),
                        ),
                        Text(
                          l10n.treasuryKpiLast8Days,
                          style: AppTypography.labelSmall.copyWith(
                            color: DashboardTones.inkSousLigne,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (open != null) ...[
                const Divider(
                  height: AppSpacing.xl,
                  color: DashboardTones.inkSousLigne,
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.treasuryKpiSeeClosing,
                        style: AppTypography.labelMedium.copyWith(
                          color: DashboardTones.inkValeur,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.arrow_forward,
                      size: AppSpacing.lg,
                      color: DashboardTones.inkValeur,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color ink;

  const _Pill({required this.icon, required this.label, required this.ink});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm + 2,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: ink.withValues(alpha: 0.22),
      borderRadius: AppRadius.brPill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.md, color: ink),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
