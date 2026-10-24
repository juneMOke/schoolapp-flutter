import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_rate_bars.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Présence jour par jour » (ou mois par mois au-delà de 31 jours de
/// classe) : une barre bichrome par pas, et sa légende.
class HrPresenceRateCard extends StatelessWidget {
  static const Color tone = DashboardSense.encaisse;

  final HrAttendanceDashboard dashboard;

  const HrPresenceRateCard({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final bars = HrPresenceLabels.bars(dashboard, l10n, dates);
    return EteeloStatsCard(
      title: dashboard.granularity == HrAttendanceGranularity.month
          ? l10n.hrPresenceChartTitleMonth
          : l10n.hrPresenceChartTitleDay,
      subtitle: l10n.hrPresenceChartSubtitle,
      icon: Icons.bar_chart_rounded,
      tone: tone,
      toneStrength: DashboardTones.forceDe(tone),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = PresenceRateBars.isNarrow(
            PresenceRateBars.barWidthFor(
              count: bars.length,
              width: constraints.maxWidth,
            ),
          );
          final scrolls = PresenceRateBars.scrollsFor(
            count: bars.length,
            width: constraints.maxWidth,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PresenceRateBars(bars: bars),
              const SizedBox(height: AppSpacing.md),
              _Legend(narrow: narrow, scrolls: scrolls),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final bool narrow;

  /// Le tracé défile : dire qu'il y a des jours plus anciens à gauche.
  final bool scrolls;

  const _Legend({required this.narrow, required this.scrolls});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final none = PresenceTone.of(PresenceStatus.none);
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Swatch(
          color: AppColors.presenceMarkPresent,
          label: l10n.hrPresenceChartLegendPresent,
        ),
        _Swatch(
          color: AppColors.presenceMarkAbsent,
          label: l10n.hrPresenceChartLegendAbsent,
        ),
        _Swatch(
          color: none.soft,
          border: none.border,
          label: l10n.hrPresenceChartLegendEmpty,
        ),
        if (scrolls)
          Text(
            l10n.hrPresenceChartScrollHint,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        if (narrow)
          Text(
            l10n.hrPresenceChartLegendNarrow,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final Color? border;
  final String label;

  const _Swatch({required this.color, required this.label, this.border});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: AppDimensions.presenceRateLegendSwatch,
        height: AppDimensions.presenceRateLegendSwatch,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDimensions.presenceRateBarRadius),
          ),
          border: border == null ? null : Border.all(color: border!),
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Flexible(
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  );
}
