import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_date_chip.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/elements/calendar_element_parts.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/elements/calendar_element_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de la vue Liste (spec §4.3, maquette `CalListView`) : liseré de
/// la nature (plein en national, voilé en interne), pastille de 38 dp (pleine
/// en cours), la durée (sauf en [compact]), l'intitulé avec « En cours » et
/// « À vérifier », puis la nature, ce qui est concerné et la source ; l'œil.
/// Un élément passé s'estompe.
class CalendarListRow extends StatelessWidget {
  final CalendarElement element;
  final SchoolEventRecord? record;
  final CalendarScopeOptions scopes;
  final DateTime today;
  final bool alternate;
  final bool first;
  final bool compact;
  final VoidCallback onTap;

  const CalendarListRow({
    super.key,
    required this.element,
    required this.record,
    required this.scopes,
    required this.today,
    required this.alternate,
    required this.first,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = element.nature.tone;
    final day = CalendarDays.of(today);
    final past = element.endDate.isBefore(day);
    final now = element.covers(day);
    final muted = AppTypography.labelSmall.copyWith(color: AppColors.textMuted);
    final accent = BorderSide(
      color: element.isNational
          ? tone.tone
          : tone.tone.withValues(
              alpha: AppDimensions.calendarListAccentSoftOpacity,
            ),
      width: AppDimensions.calendarListAccent,
    );
    return Opacity(
      opacity: past ? AppDimensions.calendarPastOpacity : 1,
      child: CalendarRowShell(
        element: element,
        current: now,
        onTap: onTap,
        background: alternate ? AppColors.calendarRowAlt : null,
        border: Border(
          left: accent,
          top: first
              ? BorderSide.none
              : const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xs / 2,
          vertical: AppSpacing.sm + AppSpacing.xs / 2,
        ),
        builder: (highlighted) => Row(
          children: [
            CalendarDateChip(
              date: element.startDate,
              tone: tone,
              strong: now,
              size: AppDimensions.calendarDateChipList,
            ),
            const SizedBox(width: AppSpacing.md),
            if (!compact) ...[
              SizedBox(
                width: AppDimensions.calendarDurationColumn,
                child: _Duration(element),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        CalendarLabels.title(l10n, element),
                        style: AppTypography.calendarRowTitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (now)
                        CalendarRowPill(
                          label: l10n.schoolCalendarWhen('now'),
                          ink: AppColors.calendarNowInk,
                          soft: AppColors.calendarNowSoft,
                        ),
                      if (element.toVerify)
                        CalendarRowPill(
                          label: l10n.schoolCalendarToVerify,
                          icon: Icons.warning_amber_rounded,
                          ink: AppColors.calendarDraftInk,
                          soft: AppColors.calendarDraftSoft,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs - AppSpacing.xs / 4),
                  Wrap(
                    spacing: AppSpacing.sm + AppSpacing.xs / 2,
                    runSpacing: AppSpacing.xs / 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CalendarNatureTag(element),
                      Text(
                        CalendarLabels.scope(l10n, element.scope, scopes),
                        style: muted,
                      ),
                      CalendarSourceTag(element),
                      if (compact)
                        Text(
                          CalendarLabels.dates(context, element),
                          style: muted,
                        ),
                    ],
                  ),
                  ...CalendarRowStatus.lines(context, element, record),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CalendarEye(tone: tone, highlighted: highlighted),
          ],
        ),
      ),
    );
  }
}

/// « → 31 oct. / 61 jours », ou « 1 jour ».
class _Duration extends StatelessWidget {
  final CalendarElement element;

  const _Duration(this.element);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = AppTypography.labelSmall.copyWith(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final days = CalendarDays.between(element.startDate, element.endDate) + 1;
    if (days == 1) {
      return Text(l10n.schoolCalendarDurationDays(1), style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '→ ${CalendarLabels.shortDay(context, element.endDate)}',
          style: style,
        ),
        Text(l10n.schoolCalendarDurationDays(days), style: style),
      ],
    );
  }
}
