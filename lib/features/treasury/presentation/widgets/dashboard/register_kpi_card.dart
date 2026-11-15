import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/balance_sparkline.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une caisse sur le tableau de bord (A2) : fond au dégradé de sa devise et
/// motif kuba, ce qu'elle détient, ce qui a bougé depuis la clôture d'hier,
/// ses 8 derniers jours. Toute la carte ouvre la clôture de la caisse.
class RegisterKpiCard extends StatefulWidget {
  final RegisterOverview overview;
  final VoidCallback? onOpen;

  const RegisterKpiCard({super.key, required this.overview, this.onOpen});

  @override
  State<RegisterKpiCard> createState() => _RegisterKpiCardState();
}

class _RegisterKpiCardState extends State<RegisterKpiCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    final open = widget.onOpen;
    final radius = BorderRadius.circular(
      AppDimensions.treasuryRegisterCardRadius,
    );
    // Survol / appui : la carte s'élève de 2 (spec A2).
    return AnimatedContainer(
      duration: AppMotion.fast,
      transform: Matrix4.translationValues(
        0,
        _hovered && open != null ? -2 : 0,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: TreasuryTones.gradient(overview.register.currency),
        boxShadow: TreasuryTones.registerShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            const KubaPatternLayer(),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: open,
                onHover: (value) => setState(() => _hovered = value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.treasuryRegisterCardPadH,
                    vertical: AppDimensions.treasuryRegisterCardPadV,
                  ),
                  child: _KpiContent(overview: overview, canOpen: open != null),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiContent extends StatelessWidget {
  final RegisterOverview overview;
  final bool canOpen;

  const _KpiContent({required this.overview, required this.canOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = overview.register;
    final currency = register.currency;
    final closure = overview.todayClosure;
    final closed = closure != null && closure.locksRegister;
    final delta = overview.deltaTodayInCents;
    final compact =
        MediaQuery.sizeOf(context).width < AppBreakpoints.phoneNarrowMax;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: AppDimensions.treasuryIconBox,
              height: AppDimensions.treasuryIconBox,
              decoration: BoxDecoration(
                color: DashboardTones.inkValeur.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(
                  AppDimensions.treasuryIconBoxRadius,
                ),
              ),
              child: const Icon(
                Icons.payments_outlined,
                size: AppSpacing.lg + 3,
                color: DashboardTones.inkValeur,
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
                      color: DashboardTones.inkValeur.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _Pill(
              icon: closed ? Icons.lock_outline : Icons.schedule,
              label: closed
                  ? l10n.treasuryKpiClosedAt(
                      TreasuryFormat.time(closure.closedAt),
                    )
                  : l10n.treasuryKpiToClose,
              fill: closed
                  ? AppColors.treasuryClosedPill
                  : AppColors.treasuryRunningPill,
              ink: closed
                  ? AppColors.treasuryClosedPillInk
                  : AppColors.treasuryRunningPillInk,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      TreasuryFormat.money(overview.balanceInCents, currency),
                      softWrap: false,
                      style: AppTextStyles.moneyTabular.copyWith(
                        color: DashboardTones.inkValeur,
                        fontWeight: FontWeight.w700,
                        fontSize: compact
                            ? AppDimensions.treasuryKpiAmountSizeCompact
                            : AppDimensions.treasuryKpiAmountSize,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Pill(
                    icon: delta < 0 ? Icons.trending_down : Icons.trending_up,
                    iconInk: delta < 0
                        ? AppColors.treasuryKpiDownInk
                        : AppColors.treasuryKpiUpInk,
                    label: TreasuryFormat.signedMoney(delta, currency),
                    trailing: l10n.treasuryKpiToday,
                    fill: DashboardTones.inkValeur.withValues(alpha: 0.12),
                    ink: DashboardTones.inkValeur,
                  ),
                ],
              ),
            ),
            if (overview.last8Days.length > 1) ...[
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BalanceSparkline(
                    days: overview.last8Days,
                    size: const Size(
                      AppDimensions.treasurySparklineWidth,
                      AppDimensions.treasurySparklineHeight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.treasuryKpiLast8Days,
                    style: AppTypography.labelSmall.copyWith(
                      color: DashboardTones.inkValeur.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (canOpen) ...[
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: DashboardTones.inkValeur.withValues(alpha: 0.14),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Flexible(
                child: Text(
                  l10n.treasuryKpiSeeClosing,
                  style: AppTypography.labelMedium.copyWith(
                    color: DashboardTones.inkValeur.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.arrow_forward,
                size: AppSpacing.md + 2,
                color: DashboardTones.inkValeur.withValues(alpha: 0.85),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color fill;
  final Color ink;
  final Color? iconInk;

  const _Pill({
    required this.icon,
    required this.label,
    required this.fill,
    required this.ink,
    this.trailing,
    this.iconInk,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: fill, borderRadius: AppRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.md, color: iconInk ?? ink),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(color: iconInk ?? ink),
                  ),
                  if (trailing != null)
                    TextSpan(
                      text: ' $trailing',
                      style: TextStyle(color: ink.withValues(alpha: 0.75)),
                    ),
                ],
              ),
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
