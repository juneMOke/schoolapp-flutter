import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_profiles.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/profiles/hr_presence_profiles_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_labels.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_attendance_report_button.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_profile_chips.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_profile_row.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_scope_bar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/states/hr_presence_results_error_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_search_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fiche individuelle, point d'entrée (spec §10) : la portée, puis la
/// liste du personnel par profil — on part toujours d'elle.
class HrPresenceProfilesBody extends StatelessWidget {
  final HrPresenceProfilesState state;
  final ValueChanged<HrAttendanceProfileRow> onOpen;

  const HrPresenceProfilesBody({
    super.key,
    required this.state,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceProfilesCubit>();
    final dates = MaterialLocalizations.of(context);
    final data = state.data;
    final year = data?.schoolYear;
    final to = data == null ? null : DateTime.tryParse(data.to);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrPersonnelHeader(subtitle: l10n.hrPresenceFicheSubtitle),
        const SizedBox(height: AppSpacing.md),
        HrPresenceScopeBar(
          yearly: state.yearly,
          onYearly: (yearly) => unawaited(cubit.setYearly(yearly)),
          month: state.month,
          isCurrentMonth: state.isCurrentMonth,
          onPrevious: state.canStepBack
              ? () => unawaited(cubit.stepMonth(-1))
              : null,
          onNext: () => unawaited(cubit.stepMonth(1)),
          onCurrent: () => unawaited(cubit.goCurrentMonth()),
          onPickMonth: () async {
            final picked = await pickPresenceMonth(
              context,
              month: state.month,
              firstMonth: state.firstMonth,
              lastMonth: state.currentMonth,
            );
            if (picked != null && !cubit.isClosed) {
              unawaited(cubit.showMonth(picked));
            }
          },
          yearLabel: year == null || to == null
              ? null
              : l10n.hrPresenceYearScope(
                  year.name,
                  HrPresenceLabels.longDate(to, dates),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _content(context, l10n, cubit),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    HrPresenceProfilesCubit cubit,
  ) {
    final data = state.data;
    switch (state.status) {
      case HrPresenceProfilesStatus.loading:
        return EteeloListSkeleton(
          rowCount: 7,
          semanticsLabel: l10n.hrPresenceProfilesLoading,
        );
      case HrPresenceProfilesStatus.failure:
        return HrPresenceResultsErrorState(
          failure: state.failure,
          onRetry: () => unawaited(cubit.retry()),
        );
      case HrPresenceProfilesStatus.ready:
        if (data == null) return const EteeloListSkeleton(rowCount: 7);
        // Un mois sans jour de classe : les vacances, pas une liste vide.
        if (!state.yearly && data.classDays == 0) {
          return PresenceHolidayState(
            month: state.month,
            onCurrent: () => unawaited(cubit.goCurrentMonth()),
          );
        }
        final rows = state.visibleRows;
        return EteeloStatsCard(
          title: l10n.hrPresenceFicheListTitle,
          subtitle: l10n.hrAgentsCount(rows.length),
          icon: Icons.badge_outlined,
          tone: DashboardSense.attendu,
          toneStrength: DashboardTones.forceDe(DashboardSense.attendu),
          // La liste affichée, sur la même question que l'écran : période,
          // recherche, catégorie et profil (règle 14).
          actions: [
            HrAttendanceReportButton(
              kind: HrAttendanceReportKind.profiles,
              onDownload: rows.isEmpty
                  ? null
                  : (report) => report.downloadProfiles(
                      state.scope,
                      search: state.text,
                      category: state.category,
                      profile: state.profile,
                    ),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaffSearchToolbar(
                text: state.text,
                label: l10n.hrPresenceStaffSearchLabel,
                placeholder: l10n.hrPresenceFicheSearchPlaceholder,
                onTextChanged: cubit.setText,
                category: state.category,
                onCategoryChanged: cubit.setCategory,
              ),
              const SizedBox(height: AppSpacing.md),
              HrPresenceProfileChips(
                counts: state.profileCounts,
                selected: state.profile,
                onToggle: cubit.toggleProfile,
              ),
              const SizedBox(height: AppSpacing.md),
              if (rows.isEmpty)
                EteeloEmptyResult(
                  label: l10n.hrPresenceStaffEmptyTitle,
                  description: l10n.hrPresenceFicheEmptyMessage,
                  medallionIcon: Icons.search_rounded,
                  fullWidthCard: true,
                  primaryAction: state.hasFilters
                      ? EteeloButton.secondary(
                          label: l10n.hrPresenceStaffShowAll,
                          icon: Icons.close,
                          onPressed: cubit.clearFilters,
                          fullWidth: false,
                        )
                      : null,
                )
              else
                for (final row in rows) ...[
                  HrPresenceProfileRow(row: row, onOpen: () => onOpen(row)),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.sm),
              const _Legend(),
            ],
          ),
        );
    }
  }
}

/// Les trois couleurs de la barre, « en % des jours pointés ».
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget swatch(PresenceStatus status, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.square_rounded,
          size: AppSpacing.md,
          color: PresenceTone.of(status).color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        swatch(PresenceStatus.present, l10n.hrPresenceLegendOnTime),
        swatch(PresenceStatus.late, l10n.hrPresenceLegendLate),
        swatch(PresenceStatus.absent, l10n.hrPresenceLegendAbsent),
        Text(
          l10n.hrPresenceLegendShare,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMutedAa,
          ),
        ),
      ],
    );
  }
}
