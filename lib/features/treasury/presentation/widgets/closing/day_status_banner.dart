import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau de la journée (B2) : « Journée en cours · 1 caisse sur 2
/// clôturée », une jauge, et le raccourci vers la première caisse à clôturer.
class DayStatusBanner extends StatelessWidget {
  final TreasuryDay day;

  /// `null` quand le raccourci n'a pas lieu d'être (jour passé, rien à
  /// clôturer, pas le droit).
  final VoidCallback? onCloseNext;
  final String? nextRegisterName;

  const DayStatusBanner({
    super.key,
    required this.day,
    this.onCloseNext,
    this.nextRegisterName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = day.registers.length;
    final closed = day.closedCount;
    final done = total > 0 && closed == total;
    final ink = done ? AppColors.success : AppColors.financeCrossedAccent;
    final close = onCloseNext;
    final next = nextRegisterName;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.08),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: ink.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(done ? Icons.lock_outline : Icons.schedule, color: ink),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      done
                          ? l10n.treasuryDayClosedTitle
                          : l10n.treasuryDayOpenTitle,
                      style: AppTypography.titleSmall.copyWith(color: ink),
                    ),
                    Text(
                      '${l10n.treasuryClosedCount(closed, total)} · '
                      '${done ? l10n.treasuryDayReportAvailable : l10n.treasuryDayReportPending}',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: AppSpacing.xxxl * 7,
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : closed / total,
                        color: ink,
                        backgroundColor: ink.withValues(alpha: 0.15),
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (close != null && next != null)
            EteeloButton.secondary(
              label: l10n.treasuryCloseShortcut(next),
              icon: Icons.lock_outline,
              onPressed: close,
              fullWidth: false,
            ),
        ],
      ),
    );
  }
}
