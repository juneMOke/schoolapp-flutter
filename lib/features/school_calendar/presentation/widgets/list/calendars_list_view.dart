import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/bloc/school_calendar_state.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_year_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La liste des calendriers (CAL §4.1, niveau 1) : l'année en vigueur dans le
/// bandeau, puis les cartes — à venir et brouillons d'abord, archives ensuite.
class CalendarsListView extends StatelessWidget {
  final SchoolCalendarState state;
  final bool canCreate;
  final VoidCallback onCreate;
  final ValueChanged<String> onOpen;

  const CalendarsListView({
    super.key,
    required this.state,
    required this.canCreate,
    required this.onCreate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inForce = state.inForce;
    final calendars = state.library.calendars;
    final archived = [
      for (final c in calendars)
        if (state.phaseOf(c) == CalendarPhase.archived ||
            state.phaseOf(c) == CalendarPhase.ended)
          c,
    ];
    final active = [
      for (final c in calendars)
        if (!archived.contains(c)) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EteeloPageHeader(
          eyebrow: l10n.schoolCalendarEyebrow,
          title: l10n.schoolCalendarTitle,
          subtitle: l10n.schoolCalendarSubtitle,
          actions: [
            if (canCreate)
              PrimaryButton(
                label: l10n.schoolCalendarNew,
                icon: Icons.add_rounded,
                fullWidth: false,
                onPressed: onCreate,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (calendars.isEmpty)
          EteeloEmptyResult(
            label: l10n.schoolCalendarEmptyTitle,
            description: l10n.schoolCalendarEmptyBody,
            medallionIcon: Icons.event_note_outlined,
            fullWidthCard: true,
            primaryAction: canCreate
                ? PrimaryButton(
                    label: l10n.schoolCalendarNew,
                    icon: Icons.add_rounded,
                    fullWidth: false,
                    onPressed: onCreate,
                  )
                : null,
          )
        else ...[
          if (inForce != null) ...[
            CalendarYearBanner(
              calendar: inForce,
              phase: CalendarPhase.inForce,
              elements:
                  state.library.frameworkOf(inForce.yearLabel)?.items ??
                  const [],
              today: state.today,
              rhythm: state.effectiveRhythm,
              eyebrow: l10n.schoolCalendarCurrentYear,
              nationalCount:
                  state.library.frameworkOf(inForce.yearLabel)?.items.length ??
                  0,
              schoolCount: 0,
              trailing: Align(
                alignment: Alignment.centerLeft,
                child: PrimaryButton(
                  label: l10n.schoolCalendarOpen,
                  icon: Icons.arrow_forward_rounded,
                  fullWidth: false,
                  onPressed: () => onOpen(inForce.yearLabel),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _CardsSection(
            title: l10n.schoolCalendarFutureSection,
            calendars: active,
            state: state,
            onOpen: onOpen,
          ),
          if (archived.isNotEmpty)
            _CardsSection(
              title: l10n.schoolCalendarArchiveSection,
              calendars: archived,
              state: state,
              onOpen: onOpen,
            ),
        ],
      ],
    );
  }
}

class _CardsSection extends StatelessWidget {
  final String title;
  final List<SchoolCalendar> calendars;
  final SchoolCalendarState state;
  final ValueChanged<String> onOpen;

  const _CardsSection({
    required this.title,
    required this.calendars,
    required this.state,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (calendars.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: EteeloPanelCard(
        title: title,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= AppBreakpoints.sideBySideMin
                ? 3
                : constraints.maxWidth >= AppBreakpoints.formGridTwoColMin
                ? 2
                : 1;
            final width =
                (constraints.maxWidth - (columns - 1) * AppSpacing.md) /
                columns;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final c in calendars)
                  SizedBox(
                    width: width,
                    child: _CalendarCard(
                      calendar: c,
                      phase: state.phaseOf(c),
                      onOpen: () => onOpen(c.yearLabel),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final SchoolCalendar calendar;
  final CalendarPhase phase;
  final VoidCallback onOpen;

  const _CalendarCard({
    required this.calendar,
    required this.phase,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final published = calendar.publishedAt;
    return EteeloActivatable(
      onActivate: onOpen,
      semanticLabel: l10n.schoolCalendarTitleYear(calendar.yearLabel),
      builder: (context, highlight) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: highlight.any ? AppColors.terreCuite : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(calendar.yearLabel, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CalendarLabels.phase(l10n, phase),
              style: AppTypography.labelMedium.copyWith(
                color: phase == CalendarPhase.draft
                    ? AppColors.terreCuiteInk
                    : AppColors.bleuArdoise,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              CalendarLabels.range(
                context,
                calendar.startDate,
                calendar.endDate,
              ),
              style: AppTypography.bodySmall,
            ),
            Text(
              calendar.hasFramework
                  ? l10n.schoolCalendarFrameworkIntegrated
                  : l10n.schoolCalendarFrameworkAwaited,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (published != null)
              Text(
                l10n.schoolCalendarPublishedOn(
                  CalendarLabels.day(context, published),
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
