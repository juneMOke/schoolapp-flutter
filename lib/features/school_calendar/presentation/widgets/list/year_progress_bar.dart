import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/school_year_progress.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'avancement de l'année sur le bandeau (spec §4.6 B) : « Semaine n / N » et
/// le pourcentage, la barre écoulée / restante, un repère au début de chaque
/// période, puis la légende « 1 sept. · repères · 3 juil. ».
class YearProgressBar extends StatelessWidget {
  final SchoolYearProgress progress;
  final DateTime startDate;
  final DateTime endDate;

  /// Le début de chaque période, dans l'année.
  final List<DateTime> markers;

  /// La légende des bornes sous la barre ; vrai par défaut. Le bandeau d'un
  /// calendrier ouvert n'en a pas.
  final bool legend;

  /// La largeur plafond ; `null` : toute la largeur reçue.
  final double? maxWidth;

  const YearProgressBar({
    super.key,
    required this.progress,
    required this.startDate,
    required this.endDate,
    required this.markers,
    this.legend = true,
    this.maxWidth = AppDimensions.calendarProgressMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final head = AppTypography.labelSmall.copyWith(
      color: AppColors.calendarHeroMuted,
      fontWeight: FontWeight.w600,
    );
    final foot = AppTypography.labelSmall.copyWith(
      color: AppColors.calendarHeroFaint,
    );
    final span = endDate.difference(startDate).inDays;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.schoolCalendarWeek(progress.week, progress.weekCount),
                  style: head,
                ),
              ),
              Text(
                l10n.schoolCalendarPercent((progress.ratio * 100).round()),
                style: head,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + AppSpacing.xs / 2),
          SizedBox(
            height: AppDimensions.calendarProgressMarkerHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    _bar(width, AppColors.calendarProgressTrack, null),
                    _bar(width * progress.ratio, null, const [
                      AppColors.calendarProgressStart,
                      AppColors.calendarProgressEnd,
                    ]),
                    if (span > 0)
                      for (final m in markers)
                        Positioned(
                          left: (width * m.difference(startDate).inDays / span)
                              .clamp(
                                0,
                                width -
                                    AppDimensions.calendarProgressMarkerWidth,
                              ),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: AppDimensions.calendarProgressMarkerWidth,
                            decoration: const BoxDecoration(
                              color: AppColors.calendarProgressMarker,
                              borderRadius: BorderRadius.all(
                                Radius.circular(
                                  AppDimensions.calendarProgressMarkerWidth / 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
          if (legend) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(CalendarLabels.shortDay(context, startDate), style: foot),
                Expanded(
                  child: Text(
                    l10n.schoolCalendarProgressMarkers,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: foot,
                  ),
                ),
                Text(CalendarLabels.shortDay(context, endDate), style: foot),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bar(double width, Color? color, List<Color>? gradient) => Container(
    width: width,
    height: AppDimensions.calendarProgressHeight,
    decoration: BoxDecoration(
      color: color,
      gradient: gradient == null ? null : LinearGradient(colors: gradient),
      borderRadius: AppRadius.brPill,
    ),
  );
}
