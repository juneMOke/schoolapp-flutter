import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_dashed_border.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/school_calendar_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/month_layout.dart';

/// Une bande d'élément sur une semaine du mois (CAL-R4) : pleine avec un
/// cadenas pour le cadre national, au contour en tirets pour l'école. En
/// compact, un trait de 6 dp sans texte, plein ou en tirets.
class CalendarMonthBand extends StatelessWidget {
  final MonthBand band;
  final bool compact;
  final bool pending;
  final VoidCallback? onTap;

  const CalendarMonthBand({
    super.key,
    required this.band,
    required this.compact,
    required this.pending,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final element = band.element;
    final tone = element.nature.tone;
    final radius = BorderRadius.horizontal(
      left: band.continuesBefore ? Radius.zero : AppRadius.sm,
      right: band.continuesAfter ? Radius.zero : AppRadius.sm,
    );
    final national = element.isNational;
    final fill = national ? tone.tone : tone.soft;
    Widget body = compact
        ? const SizedBox.expand()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                if (national)
                  Icon(
                    SchoolCalendarTones.nationalIcon,
                    size: AppSpacing.md,
                    color: tone.soft,
                  ),
                if (pending)
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: AppSpacing.md,
                    color: tone.ink,
                  ),
                const SizedBox(width: AppSpacing.xs / 2),
                Expanded(
                  child: Text(
                    element.title,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: national ? tone.soft : tone.ink,
                    ),
                  ),
                ),
              ],
            ),
          );
    body = DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: national
          ? body
          : CustomPaint(
              foregroundPainter: DashedRRectPainter(
                color: tone.tone,
                borderRadius: radius,
                strokeWidth: AppDimensions.calendarBandDashStroke,
                dash: compact
                    ? AppDimensions.calendarBandCompactDash
                    : AppDimensions.calendarBandDash,
                gap: compact
                    ? AppDimensions.calendarBandCompactDashGap
                    : AppDimensions.calendarBandDashGap,
              ),
              child: body,
            ),
    );
    // Un raccourci de pointeur, pas une cible : 18 dp ne tiennent pas les
    // 48 dp (A18). La case du jour, dessous, porte le geste accessible (I6 :
    // un seul élément ouvre son détail, plusieurs filtrent la liste).
    final tap = onTap;
    return ExcludeSemantics(
      child: Tooltip(
        message: element.title,
        child: tap == null
            ? body
            : MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: tap, child: body),
              ),
      ),
    );
  }
}
