import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_day.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
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
    final tone = done ? TreasuryTones.inflow : TreasuryTones.pending;
    final ink = tone.ink;
    final close = onCloseNext;
    final next = nextRegisterName;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(
          AppDimensions.treasuryRemainingRadius,
        ),
        border: Border.all(color: tone.border),
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
              Container(
                width: AppDimensions.treasuryReportPictogram,
                height: AppDimensions.treasuryReportPictogram,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.treasuryFormatButtonRadius,
                  ),
                ),
                child: Icon(
                  done ? Icons.lock_outline : Icons.schedule,
                  size: AppSpacing.lg + 2,
                  color: AppColors.surfaceRaised,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          done
                              ? l10n.treasuryDayClosedTitle
                              : l10n.treasuryDayOpenTitle,
                          style: AppTypography.titleSmall.copyWith(color: ink),
                        ),
                        // Une pastille par caisse : pleine si clôturée.
                        for (final r in day.registers)
                          Tooltip(
                            message: r.register.name,
                            child: Container(
                              width: AppSpacing.md,
                              height: AppSpacing.md,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: r.isClosed
                                    ? TreasuryTones.inflow.ink
                                    : null,
                                border: Border.all(
                                  color: r.isClosed
                                      ? TreasuryTones.inflow.ink
                                      : TreasuryTones.pending.ink,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
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
