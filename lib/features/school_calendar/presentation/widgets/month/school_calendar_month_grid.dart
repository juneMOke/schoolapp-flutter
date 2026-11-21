import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_month_painters.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_weekday_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/month_layout.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_month_band.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_month_day_cell.dart';

/// Le mois du calendrier scolaire (🆕, spec Calendrier §4.6 D, maquette
/// `CalMonthView`) : une carte, un bandeau des jours (lundi en premier), une
/// rangée par semaine en cases jointives, les éléments en bandes continues.
///
/// [narrow] (sous 900 dp reçus) : jours abrégés, cases plus basses, ni
/// « Aujourd'hui » ni mois au 1er. [compact] (sous 600) : deux lettres par
/// jour, bandes en traits de 6 dp sans texte, trois couloirs, et toucher un
/// jour le **sélectionne** ([onDayTap]) au lieu d'ouvrir une bande.
///
/// Pourquoi neuf : rien dans le socle ne pose des événements de plusieurs
/// jours en bandes ; `HrPresenceMonthBody` ne montre qu'un état par jour.
class SchoolCalendarMonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final List<CalendarElement> elements;
  final DateTime today;
  final bool compact;
  final bool narrow;
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
    this.narrow = false,
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
      maxLanes: compact || narrow ? _compactLanes : _lanes,
    );
    final labels = CalendarWeekdayLabels.header(
      context,
      compact: compact,
      narrow: narrow,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.calendarUpcomingBorder),
        boxShadow: AppElevation.shadowKpi,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: AppColors.calendarMonthHeader,
              child: Row(
                children: [
                  for (final (i, label) in labels.indexed)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: compact
                              ? AppSpacing.sm
                              : AppDimensions.calendarMonthHeaderPadding,
                          horizontal: AppSpacing.xs / 2,
                        ),
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : const Border(
                                  left: BorderSide(
                                    color: AppColors.calendarMonthHeaderDivider,
                                  ),
                                ),
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: i >= 5
                                  ? AppColors.calendarMonthHeaderWeekend
                                  : AppColors.textOnDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (final (i, week) in weeks.indexed)
              _WeekRow(grid: this, week: week, first: i == 0),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final SchoolCalendarMonthGrid grid;
  final MonthWeek week;
  final bool first;

  const _WeekRow({required this.grid, required this.week, required this.first});

  @override
  Widget build(BuildContext context) {
    final compact = grid.compact;
    final scaler = MediaQuery.textScalerOf(context);
    // Le texte grossi (×1,3) grandit l'en-tête, les bandes à libellé et
    // « +n autres » : aucune hauteur fixe (A17), la rangée se calcule.
    final bandHeight = compact
        ? AppDimensions.calendarBandCompactHeight
        : scaler.scale(AppDimensions.calendarBandHeight);
    final gap = compact
        ? AppDimensions.calendarBandCompactRowGap
        : AppDimensions.calendarBandRowGap;
    final top = compact ? AppSpacing.xs : AppSpacing.xs + AppSpacing.xs / 2;
    final header = scaler.scale(AppDimensions.calendarMonthDayHeader);
    final lanes = week.bands.isEmpty
        ? 0
        : week.bands.map((b) => b.lane).reduce((a, b) => a > b ? a : b) + 1;
    final more = week.hiddenByCol.any((n) => n > 0)
        ? scaler.scale(AppDimensions.calendarMonthDayHeader)
        : 0.0;
    final minHeight = compact
        ? AppDimensions.calendarMonthCompactCellMinHeight
        : grid.narrow
        ? AppDimensions.calendarMonthCellMinHeightNarrow
        : AppDimensions.calendarMonthCellMinHeightWide;
    final content =
        top + header + gap + lanes * (bandHeight + gap) + more + AppSpacing.sm;
    final rowHeight = content > minHeight ? content : minHeight;
    // Au premier plan : en fond, les cases opaques des jours recouvraient le
    // filet du haut, et les semaines n'avaient plus de bord haut ni bas.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(
                top: BorderSide(color: AppColors.calendarMonthGridLine),
              ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colWidth = constraints.maxWidth / 7;
          final inset = compact
              ? AppDimensions.calendarBandCompactInset
              : AppDimensions.calendarBandInset;
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
                          top: top,
                          day: week.days[col],
                          inMonth: week.days[col].month == grid.month,
                          isToday: week.days[col] == grid.today,
                          isSelected: week.days[col] == grid.selectedDay,
                          compact: compact,
                          narrow: grid.narrow || compact,
                          first: col == 0,
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
                    left:
                        band.startCol * colWidth +
                        (band.continuesBefore ? 0 : inset),
                    width:
                        (band.endCol - band.startCol + 1) * colWidth -
                        (band.continuesBefore ? 0 : inset) -
                        (band.continuesAfter ? 0 : inset),
                    top: top + header + gap + band.lane * (bandHeight + gap),
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
                // Les traits entre les jours et le cadre du jour, au-dessus
                // des bandes : chaque jour reste une case distincte.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: CalendarWeekOverlayPainter(
                        todayCol: _col(week, grid.today),
                        selectedCol: _col(week, grid.selectedDay),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static int? _col(MonthWeek week, DateTime? day) {
    if (day == null) return null;
    final i = week.days.indexOf(day);
    return i < 0 ? null : i;
  }
}
