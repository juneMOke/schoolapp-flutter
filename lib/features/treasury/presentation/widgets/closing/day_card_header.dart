import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/currency_tones.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête d'une carte « caisse du jour » : le pavé de la devise, le nom, la
/// date longue et la pastille d'état.
class DayCardHeader extends StatelessWidget {
  final CashDaySummary summary;
  final DateTime date;
  final bool isToday;

  const DayCardHeader({
    super.key,
    required this.summary,
    required this.date,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = summary.register;
    final pill = _pill(l10n);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg + 2,
        vertical: AppSpacing.md + 2,
      ),
      color: CurrencyTones.pave(register.currency.code),
      // Sur une carte étroite, la pastille passe sous le nom plutôt que de
      // tronquer l'état de la caisse.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                summary.isClosed ? Icons.lock_outline : Icons.payments_outlined,
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
                      l10n.treasuryDayLong(date),
                      style: AppTypography.labelSmall.copyWith(
                        color: DashboardTones.inkSousLigne,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ?pill,
        ],
      ),
    );
  }

  /// Ouverte · à clôturer (aujourd'hui), Clôturée 17:45 (· écart), ou
  /// Non clôturée (jour passé).
  Widget? _pill(AppLocalizations l10n) {
    final closure = summary.closure;
    if (closure != null && closure.locksRegister) {
      final time = TreasuryFormat.time(closure.closedAt);
      return _Pill(
        icon: Icons.lock_outline,
        label: closure.hasGap
            ? l10n.treasuryClosedAtGapShort(time)
            : l10n.treasuryClosedAtShort(time),
        ink: closure.hasGap ? AppColors.paveInkReste : AppColors.paveInkPercu,
      );
    }
    if (isToday) {
      return _Pill(
        icon: Icons.schedule,
        label: l10n.treasuryOpenToClose,
        ink: AppColors.paveInkAttendu,
      );
    }
    return _Pill(
      icon: Icons.warning_amber_outlined,
      label: l10n.treasuryNotClosed,
      ink: AppColors.paveInkAttendu,
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
        // L'état passe à la ligne s'il le faut ; il n'est jamais tronqué.
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
