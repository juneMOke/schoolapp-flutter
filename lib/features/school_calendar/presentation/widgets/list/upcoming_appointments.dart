import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/list/upcoming_appointment_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Prochains rendez-vous » (spec §4.6 R, maquette `CalList`) : les six
/// prochains éléments (hors périodes) de l'année en vigueur, en cartes de
/// 230 dp qui défilent de côté, ascenseur visible. Toucher une carte ouvre
/// le calendrier.
class UpcomingAppointments extends StatefulWidget {
  final String yearLabel;
  final List<CalendarElement> elements;
  final DateTime today;
  final VoidCallback onOpen;

  const UpcomingAppointments({
    super.key,
    required this.yearLabel,
    required this.elements,
    required this.today,
    required this.onOpen,
  });

  static const maxCount = 6;

  /// Les prochains éléments, en cours compris, dans l'ordre des dates.
  static List<CalendarElement> pick(
    List<CalendarElement> elements,
    DateTime today,
  ) {
    final up = [
      for (final e in elements)
        if (e.nature != CalendarNature.period && !e.endDate.isBefore(today)) e,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));
    return up.take(maxCount).toList();
  }

  @override
  State<UpcomingAppointments> createState() => _UpcomingAppointmentsState();
}

class _UpcomingAppointmentsState extends State<UpcomingAppointments> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final up = UpcomingAppointments.pick(widget.elements, widget.today);
    if (up.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs / 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.calendarUpcomingStart,
            AppColors.calendarUpcomingMid,
            AppColors.calendarUpcomingEnd,
          ],
        ),
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.calendarUpcomingBorder),
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.calendarUpcomingMedallion,
                height: AppDimensions.calendarUpcomingMedallion,
                decoration: const BoxDecoration(
                  color: AppColors.terreCuite,
                  borderRadius: AppRadius.brSm,
                ),
                child: const Icon(
                  Icons.edit_calendar_outlined,
                  size: AppDimensions.calendarUpcomingMedallionIcon,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.schoolCalendarUpcomingSection,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.bleuProfond,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '· ${widget.yearLabel}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md - AppSpacing.xs / 2),
          ScrollbarTheme(
            data: const ScrollbarThemeData(
              thickness: WidgetStatePropertyAll(
                AppDimensions.calendarNatureBarHeight,
              ),
              thumbColor: WidgetStatePropertyAll(AppColors.calendarScrollThumb),
              radius: AppRadius.sm,
            ),
            child: Scrollbar(
              controller: _scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, e) in up.indexed) ...[
                        if (i > 0)
                          const SizedBox(
                            width: AppSpacing.md - AppSpacing.xs / 2,
                          ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: AppDimensions.calendarUpcomingCardWidth,
                            maxWidth:
                                AppDimensions.calendarUpcomingCardMaxWidth,
                          ),
                          child: UpcomingAppointmentCard(
                            element: e,
                            today: widget.today,
                            onTap: widget.onOpen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
