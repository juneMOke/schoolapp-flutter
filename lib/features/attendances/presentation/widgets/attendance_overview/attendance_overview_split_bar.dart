import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_kpis.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_overview_format.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Repartition presence / absences justifiees / absences non justifiees sous
/// la forme d'une barre empilee 100 % (les trois taux totalisent 100 %) suivie
/// d'une legende. Lecture seule.
class AttendanceOverviewSplitBar extends StatelessWidget {
  final AttendanceKpis kpis;

  const AttendanceOverviewSplitBar({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Trois segments dans l'ordre presence -> justifiee -> non justifiee.
    final segments = <_SplitSegment>[
      _SplitSegment(
        rate: kpis.presenceRate,
        color: AppColors.vertSavane,
        label: l10n.attendanceOverviewSplitPresence,
      ),
      _SplitSegment(
        rate: kpis.justifiedAbsenceRate,
        color: AppColors.warning,
        label: l10n.attendanceOverviewSplitJustified,
      ),
      _SplitSegment(
        rate: kpis.unjustifiedAbsenceRate,
        color: AppColors.error,
        label: l10n.attendanceOverviewSplitUnjustified,
      ),
    ];

    return AttendanceOverviewCard(
      title: l10n.attendanceOverviewSplitTitle,
      hint: l10n.attendanceOverviewSplitSumHint,
      hintTrailing: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBar(context, l10n, segments),
          const SizedBox(height: AppDimensions.spacingM),
          _buildLegend(context, l10n, segments),
        ],
      ),
    );
  }

  /// Barre empilee 100 % : un [Row] de trois [Expanded] dont le flex suit le
  /// taux (precision 0,1 % via *10). Coins arrondis (clip antiAlias). Les
  /// largeurs sont transitionnees a l'arrivee des donnees (spec PARCOURS-3),
  /// sauf en reduced-motion ou l'etat final est rendu directement.
  Widget _buildBar(
    BuildContext context,
    AppLocalizations l10n,
    List<_SplitSegment> segments,
  ) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // [t] = progression 0 -> 1 : les segments « se remplissent » depuis la
    // gauche (un espaceur final retrecit a mesure que t croit).
    Widget barAt(double t) {
      final totalTarget = segments.fold<double>(
        0,
        (sum, segment) => sum + segment.rate * 10,
      );
      final spacerFlex = (totalTarget * (1 - t)).round();
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: ColoredBox(
          color: AppColors.surfaceAlt,
          child: SizedBox(
            height: AppDimensions.attendanceOverviewSplitBarHeight,
            child: Row(
              children: [
                for (final segment in segments)
                  Expanded(
                    flex: (segment.rate * 10 * t).round(),
                    child: Tooltip(
                      message:
                          '${segment.label} · '
                          '${l10n.attendanceOverviewRateValue(AttendanceOverviewFormat.rate(segment.rate, context))}',
                      child: ColoredBox(color: segment.color),
                    ),
                  ),
                if (spacerFlex > 0)
                  Expanded(flex: spacerFlex, child: const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      image: true,
      label: l10n.attendanceOverviewSplitA11yLabel(
        AttendanceOverviewFormat.rate(kpis.presenceRate, context),
        AttendanceOverviewFormat.rate(kpis.justifiedAbsenceRate, context),
        AttendanceOverviewFormat.rate(kpis.unjustifiedAbsenceRate, context),
      ),
      child: reduceMotion
          ? barAt(1)
          : TweenAnimationBuilder<double>(
              key: ValueKey<String>(
                '${kpis.presenceRate}-${kpis.justifiedAbsenceRate}-${kpis.unjustifiedAbsenceRate}',
              ),
              tween: Tween<double>(begin: 0, end: 1),
              duration: AppMotion.layout,
              curve: AppMotion.outCurve,
              builder: (context, t, _) => barAt(t),
            ),
    );
  }

  /// Legende : pastille 11 dp + libelle + valeur en gras coloree par segment.
  Widget _buildLegend(
    BuildContext context,
    AppLocalizations l10n,
    List<_SplitSegment> segments,
  ) {
    return Wrap(
      spacing: AppDimensions.spacingL,
      runSpacing: AppDimensions.spacingS,
      children: [
        for (final segment in segments)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: segment.color,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                segment.label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                l10n.attendanceOverviewRateValue(
                  AttendanceOverviewFormat.rate(segment.rate, context),
                ),
                style: AppTextStyles.bodyStrong.copyWith(
                  color: segment.color,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Donnees d'un segment de la barre / d'une entree de legende.
class _SplitSegment {
  final double rate;
  final Color color;
  final String label;

  const _SplitSegment({
    required this.rate,
    required this.color,
    required this.label,
  });
}
