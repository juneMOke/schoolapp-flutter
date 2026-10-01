import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_rate_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_card_frame.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_filter_empty.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_totals_band.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_month_recap.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_month_close.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/widgets/class_recap_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet « Récapitulatif du mois » : totaux, filtres, une ligne par élève.
class ClassRecapTab extends StatelessWidget {
  final ClassPresenceState state;

  const ClassRecapTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ClassPresenceCubit>();
    final recap = state.recap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            PresenceMonthNav(
              month: state.month,
              isCurrent: state.isCurrentMonth,
              onPrevious: state.canStepMonthBack
                  ? () => unawaited(cubit.stepMonth(-1))
                  : null,
              onNext: () => unawaited(cubit.stepMonth(1)),
              onCurrent: () => unawaited(cubit.goCurrentMonth()),
            ),
            if (recap != null)
              ClassMonthCloseButton(state: state, recap: recap),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (recap == null)
          const EteeloListSkeleton(rowCount: 6)
        else if (recap.isHoliday)
          PresenceHolidayState(
            month: state.month,
            onCurrent: () => unawaited(cubit.goCurrentMonth()),
          )
        else ...[
          ClassMonthCloseState(state: state, closure: recap.month.closure),
          const SizedBox(height: AppSpacing.md),
          _Totals(state: state, recap: recap),
          const SizedBox(height: AppSpacing.md),
          _Filters(state: state, recap: recap),
          const SizedBox(height: AppSpacing.md),
          if (recap.isFilteredEmpty)
            PresenceFilterEmpty(
              label: l10n.classPresenceRecapEmptyFilter,
              allMarked: false,
              onShowAll: cubit.resetRecapFilters,
            )
          else
            PresenceCardFrame(
              child: ClassRecapTable(
                rows: recap.rows,
                sync: recap.month.sync,
                onOpen: (row) => cubit.openStudent(row.student.id),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.classPresenceRecapLegend,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        ],
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  final ClassPresenceState state;
  final ClassMonthRecap recap;

  const _Totals({required this.state, required this.recap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rate = recap.rate;
    final days = [
      l10n.classPresenceRecapDays(recap.schoolDays),
      if (state.isCurrentMonth) l10n.classPresenceRecapToDate,
    ].join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n
              .classPresenceRecapEyebrow(state.classroom?.name ?? '')
              .toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMutedAa,
          ),
        ),
        Text(
          '$days · ${l10n.classPresenceRecapStudents(recap.all.length)}',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        PresenceTotalsBand(
          totals: [
            (
              l10n.presenceMarkTotalRate,
              rate == null
                  ? '—'
                  : l10n.classPresenceKpiRate(PresenceRateTone.percent(rate)),
            ),
            (
              l10n.classPresenceTotalLates,
              l10n.classPresenceLatesValue(recap.late, recap.lateMinutes),
            ),
            (l10n.presenceMarkTotalUnjustified, '${recap.absentUnjustified}'),
            (
              l10n.classPresenceTotalToWatch,
              '${recap.count(ClassRecapFilter.toWatch)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  final ClassPresenceState state;
  final ClassMonthRecap recap;

  const _Filters({required this.state, required this.recap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ClassPresenceCubit>();
    final query = state.recapQuery;
    Widget chip(ClassRecapFilter filter, String label, PresenceTone tone) =>
        EteeloFilterChip(
          label: label,
          count: recap.count(filter),
          selected: query.filter == filter,
          color: tone.color,
          soft: tone.soft,
          ink: tone.ink,
          onTap: () => cubit.setRecapFilter(filter),
        );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            chip(
              ClassRecapFilter.all,
              l10n.presenceMarkFilterAll,
              PresenceTone.of(PresenceStatus.none),
            ),
            chip(
              ClassRecapFilter.toWatch,
              l10n.classPresenceFilterToWatch,
              PresenceTone.of(PresenceStatus.absent),
            ),
            chip(
              ClassRecapFilter.perfect,
              l10n.classPresenceFilterPerfect,
              PresenceTone.of(PresenceStatus.present),
            ),
          ],
        ),
        EteeloSearchToolbar(
          text: query.text,
          label: l10n.classPresenceSearchLabel,
          placeholder: l10n.classPresenceSearchPlaceholder,
          onTextChanged: cubit.setRecapText,
        ),
      ],
    );
  }
}
