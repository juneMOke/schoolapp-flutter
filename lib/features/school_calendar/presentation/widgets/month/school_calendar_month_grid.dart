import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_weekday_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/month_layout.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_month_band.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_month_day_cell.dart';

/// Le mois du calendrier scolaire (🆕, spec Calendrier §4.6 D) : sept colonnes,
/// lundi en premier, une rangée par semaine, les éléments en bandes continues.
///
/// [compact] (largeur reçue sous `AppBreakpoints.calendarMonthCompactMax`) :
/// initiales des jours, bandes en traits de 6 dp sans texte, trois couloirs,
/// et toucher un jour le **sélectionne** ([onDayTap]) au lieu d'ouvrir une
/// bande.
///
/// Pourquoi neuf : rien dans le socle ne pose des événements de plusieurs
/// jours en bandes ; `HrPresenceMonthBody` ne montre qu'un état par jour.
class SchoolCalendarMonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final List<CalendarElement> elements;
  final DateTime today;
  final bool compact;
  final DateTime? selectedDay;

  /// Les éléments en attente d'envoi (hors ligne), marqués sur leur bande.
  final Set<String> pendingIds;
  final ValueChanged<CalendarElement>? onElementTap;
  final ValueChanged<DateTime>? onDayTap;

  const SchoolCalendarMonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.elements,
    required this.today,
    this.compact = false,
    this.selectedDay,
    this.pendingIds = const {},
    this.onElementTap,
    this.onDayTap,
  });

  static const int _lanes = 4;
  static const int _compactLanes = 3;

  @override
  Widget build(BuildContext context) {
    final weeks = MonthLayout.compute(
      year: year,
      month: month,
      elements: elements,
      maxLanes: compact ? _compactLanes : _lanes,
    );
    final weekdayLabels = CalendarWeekdayLabels.of(context, compact: compact);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final week in weeks) _WeekRow(grid: this, week: week),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  final SchoolCalendarMonthGrid grid;
  final MonthWeek week;

  const _WeekRow({required this.grid, required this.week});

  @override
  Widget build(BuildContext context) {
    final compact = grid.compact;
    final scaler = MediaQuery.textScalerOf(context);
    // Le texte grossi (×1,3) grandit l'en-tête, les bandes à libellé et
    // « +n autres » : aucune hauteur fixe (A17), la rangée se calcule.
    final bandHeight = compact
        ? AppDimensions.calendarBandCompactHeight
        : scaler.scale(AppDimensions.calendarBandHeight);
    final header = scaler.scale(AppDimensions.calendarMonthDayHeader);
    final lanes = week.bands.isEmpty
        ? 0
        : week.bands.map((b) => b.lane).reduce((a, b) => a > b ? a : b) + 1;
    final more = week.hiddenByCol.any((n) => n > 0)
        ? scaler.scale(AppDimensions.calendarMonthDayHeader)
        : 0.0;
    final minHeight = compact
        ? AppDimensions.calendarMonthCompactCellMinHeight
        : AppDimensions.calendarMonthCellMinHeight;
    final content =
        AppSpacing.xs +
        header +
        lanes * (bandHeight + AppDimensions.calendarBandGap) +
        more;
    final rowHeight = content > minHeight ? content : minHeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final colWidth = constraints.maxWidth / 7;
        return SizedBox(
          height: rowHeight,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: CalendarMonthDayCell(
                        day: week.days[col],
                        inMonth: week.days[col].month == grid.month,
                        isToday: week.days[col] == grid.today,
                        isSelected: week.days[col] == grid.selectedDay,
                        compact: compact,
                        headerHeight: header,
                        hidden: week.hiddenByCol[col],
                        onTap: grid.onDayTap == null
                            ? null
                            : () => grid.onDayTap!(week.days[col]),
                      ),
                    ),
                ],
              ),
              for (final band in week.bands)
                Positioned(
                  left: band.startCol * colWidth + AppSpacing.xs / 2,
                  width:
                      (band.endCol - band.startCol + 1) * colWidth -
                      AppSpacing.xs,
                  top:
                      AppSpacing.xs / 2 +
                      header +
                      band.lane * (bandHeight + AppDimensions.calendarBandGap),
                  height: bandHeight,
                  child: CalendarMonthBand(
                    band: band,
                    compact: compact,
                    pending: grid.pendingIds.contains(band.element.id),
                    // Compact : la bande n'est pas une cible, le jour l'est.
                    onTap: compact || grid.onElementTap == null
                        ? null
                        : () => grid.onElementTap!(band.element),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
