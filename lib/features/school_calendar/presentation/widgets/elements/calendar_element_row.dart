import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/status/pending_sync_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_date_chip.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/elements/calendar_element_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de la liste du mois (spec §4.6 E, maquette `CalMonthSide`) :
/// pastille de 34 dp (au premier jour affiché), l'intitulé, puis le cadenas
/// ou le carré en tirets, les dates et — si ce n'est pas toute l'école — ce
/// qui est concerné ; l'œil à droite. La ligne en cours prend un fond
/// terre cuite pâle.
class CalendarSideRow extends StatelessWidget {
  final CalendarElement element;
  final SchoolEventRecord? record;
  final CalendarScopeOptions scopes;
  final DateTime chipDate;
  final bool current;
  final VoidCallback onTap;

  const CalendarSideRow({
    super.key,
    required this.element,
    required this.record,
    required this.scopes,
    required this.chipDate,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = element.nature.tone;
    final meta = [
      CalendarLabels.dates(context, element),
      if (element.scope is! SchoolScope)
        CalendarLabels.scope(l10n, element.scope, scopes),
    ].join(' · ');
    return CalendarRowShell(
      element: element,
      current: current,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      builder: (highlighted) => Row(
        children: [
          CalendarDateChip(
            date: chipDate,
            tone: tone,
            strong: current,
            size: AppDimensions.calendarDateChipSmall,
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  element.title,
                  style: AppTypography.calendarRowTitleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                      child: CalendarSourceMark(element),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        meta,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                ...CalendarRowStatus.lines(context, element, record),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CalendarEye(tone: tone, small: true, highlighted: highlighted),
        ],
      ),
    );
  }
}

/// Le contour commun d'une ligne d'élément : cible tactile, fond en cours ou
/// survolé, filet du haut.
class CalendarRowShell extends StatelessWidget {
  final CalendarElement element;
  final bool current;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final BoxBorder? border;
  final Widget Function(bool highlighted) builder;

  const CalendarRowShell({
    super.key,
    required this.element,
    required this.current,
    required this.onTap,
    required this.padding,
    required this.builder,
    this.background,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final tone = element.nature.tone;
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel:
          '${element.title}, ${CalendarLabels.dates(context, element)}',
      builder: (context, highlight) => ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.minTouchTarget,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: highlight.any
                ? Color.alphaBlend(
                    tone.tone.withValues(
                      alpha: AppDimensions.calendarRowHoverOpacity,
                    ),
                    AppColors.surfaceRaised,
                  )
                : current
                ? null
                : background ?? AppColors.surfaceRaised,
            gradient: current && !highlight.any
                ? const LinearGradient(
                    colors: [AppColors.calendarNowRow, AppColors.surfaceRaised],
                  )
                : null,
            border:
                border ??
                const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: builder(highlight.any),
        ),
      ),
    );
  }
}

/// Ce qui suit l'état d'envoi d'un événement : en attente, ou refusé.
class CalendarRowStatus {
  const CalendarRowStatus._();

  static List<Widget> lines(
    BuildContext context,
    CalendarElement element,
    SchoolEventRecord? record,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return [
      if (record?.isPending ?? false)
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.xs),
          child: PendingSyncBadge(),
        ),
      if (record?.isRejected ?? false)
        Text(
          l10n.schoolCalendarRejected(
            CalendarLabels.refusalCode(l10n, record?.errorCode),
          ),
          style: AppTypography.bodySmall.copyWith(color: AppColors.error),
        ),
    ];
  }
}
