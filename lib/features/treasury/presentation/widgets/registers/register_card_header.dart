import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/balance_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête d'une carte de caisse : le pavé de la devise, son nom, et ce que
/// la caisse détient — le déclaré si elle est clôturée aujourd'hui, l'attendu
/// sinon (le serveur l'a déjà choisi : `balanceInCents`).
class RegisterCardHeader extends StatelessWidget {
  final RegisterConfig config;
  final bool isNew;

  const RegisterCardHeader({
    super.key,
    required this.config,
    required this.isNew,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = config.register;
    final currency = register.currency;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg + 2,
        vertical: AppSpacing.lg,
      ),
      color: CurrencyTones.pave(currency.code),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.treasuryRegisterBadge,
                height: AppDimensions.treasuryRegisterBadge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DashboardTones.inkValeur.withValues(
                    alpha: EteeloKpiCard.filledMedallionVeil,
                  ),
                  borderRadius: AppRadius.brMd,
                ),
                child: Text(
                  TreasuryFormat.symbol(currency),
                  style: AppTypography.labelLarge.copyWith(
                    color: DashboardTones.inkValeur,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
                      TreasuryFormat.currencyName(l10n, currency),
                      style: AppTypography.labelSmall.copyWith(
                        color: DashboardTones.inkSousLigne,
                      ),
                    ),
                  ],
                ),
              ),
              if (isNew) _NewPill(label: l10n.treasuryBadgeNew),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Le montant ne passe jamais à la ligne et ne se tronque jamais :
          // s'il manque de place, il rétrécit.
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    TreasuryFormat.money(config.balanceInCents, currency),
                    softWrap: false,
                    style: AppTextStyles.totalAmountLora.copyWith(
                      fontSize: 28,
                      height: 1.1,
                      color: DashboardTones.inkValeur,
                    ),
                  ),
                ),
              ),
              // Les 8 derniers jours, à droite du montant, quand la caisse a
              // un historique (C1).
              if (config.last8Days.length > 1) ...[
                const SizedBox(width: AppSpacing.md),
                BalanceSparkline(
                  days: config.last8Days,
                  size: const Size(
                    AppDimensions.treasuryConfigSparklineWidth,
                    AppDimensions.treasuryConfigSparklineHeight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _subline(l10n),
            style: AppTypography.bodySmall.copyWith(
              color: DashboardTones.inkSousLigne,
            ),
          ),
        ],
      ),
    );
  }

  String _subline(AppLocalizations l10n) {
    final closure = config.todayClosure;
    if (closure == null || !closure.locksRegister) {
      return l10n.treasuryHeldToday;
    }
    final time = TreasuryFormat.time(closure.closedAt);
    if (closure.gapInCents == 0) return l10n.treasuryDeclaredAt(time);
    return l10n.treasuryDeclaredAtWithGap(
      time,
      TreasuryFormat.signedMoney(closure.gapInCents, config.register.currency),
    );
  }
}

class _NewPill extends StatelessWidget {
  final String label;

  const _NewPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs / 2,
    ),
    decoration: const BoxDecoration(
      color: AppColors.orDoux,
      borderRadius: AppRadius.brPill,
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.bleuProfond,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
