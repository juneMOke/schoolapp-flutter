import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_holiday_state.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_person_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/agent/hr_presence_month_body.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_fiche_kpis.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_profile_card.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_scope_bar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_year_list.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/hr_fiche_location.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/states/hr_presence_results_error_state.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Présences ▸ Fiche individuelle ▸ un agent (spec §12) : son profil,
/// en vue mensuelle (route 2) ou annuelle (route 3), par-dessus la liste —
/// `/home/rh-presences-fiche/{agentId}?vue=an` ou `?mois=AAAA-MM`.
class HrPresenceFicheAgentPage extends StatelessWidget {
  final HrPresenceFicheArgs args;
  final VoidCallback? onClosed;

  const HrPresenceFicheAgentPage({
    super.key,
    required this.args,
    this.onClosed,
  });

  /// Ouvre la fiche de [agentId] sur la portée de l'écran qui l'ouvre, et se
  /// termine quand elle se referme.
  static Future<void> open(
    BuildContext context, {
    required String agentId,
    required bool yearly,
    required String month,
  }) => HrAgentIntent.open(
    context,
    subMenuId: MenuConstants.hrPresenceFicheId,
    agentId: agentId,
    query: yearly
        ? {HrFicheLocation.viewParam: HrFicheLocation.yearValue}
        : {HrFicheLocation.monthParam: month},
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => getIt<HrPresenceFicheCubit>(
      param1: (
        agentId: args.agentId,
        yearly: args.yearly,
        month: args.month,
        yearStart: args.yearStart ?? _yearStart(context),
      ),
    )..load(),
    child: _Closing(
      onClosed: onClosed,
      child: const HrPresenceFicheAgentScreen(),
    ),
  );

  static DateTime? _yearStart(BuildContext context) {
    try {
      return context
          .read<AcademicYearContextBloc>()
          .state
          .context
          ?.academicYear
          .startDate;
    } on Object {
      return null;
    }
  }
}

class _Closing extends StatefulWidget {
  final VoidCallback? onClosed;
  final Widget child;

  const _Closing({required this.onClosed, required this.child});

  @override
  State<_Closing> createState() => _ClosingState();
}

class _ClosingState extends State<_Closing> {
  @override
  void dispose() {
    widget.onClosed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class HrPresenceFicheAgentScreen extends StatelessWidget {
  const HrPresenceFicheAgentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceFicheCubit>();
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(cubit.retry()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        appBar: OffShellTopBar(
          eyebrow: l10n.hrPresenceEyebrow,
          title: l10n.subMenuHrPresenceFiche,
          backTooltip: l10n.hrPresenceStaffList,
          shellSubMenuId: MenuConstants.hrPresenceFicheId,
        ),
        child: BlocBuilder<HrPresenceFicheCubit, HrPresenceFicheState>(
          builder: (context, state) => _body(context, l10n, cubit, state),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    HrPresenceFicheCubit cubit,
    HrPresenceFicheState state,
  ) {
    final dates = MaterialLocalizations.of(context);
    final members = state.members;
    final toolbar = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: [
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
          yearLabel: state.yearData?.schoolYear.name,
        ),
        if (members.isNotEmpty)
          PresencePersonPicker<StaffMember>(
            entries: [
              for (final m in members)
                PresencePickerEntry(
                  value: m,
                  id: m.id,
                  firstName: m.firstName,
                  lastName: m.lastName,
                  fullName: m.fullName,
                  detail: m.jobTitle,
                ),
            ],
            selectedId: state.agentId,
            label: l10n.staffAttendanceTabAgent,
            placeholder: l10n.staffAttendanceAgentPicker,
            matches: StaffMemberSearch.matches,
            onSelected: (picked) => unawaited(cubit.openAgent(picked.id)),
          ),
      ],
    );
    final month = state.monthData;
    final year = state.yearData;
    final Widget content = switch (state.status) {
      HrPresenceFicheStatus.loading => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloKpiBandSkeleton(count: 4),
          SizedBox(height: AppSpacing.lg),
          EteeloListSkeleton(rowCount: 5),
        ],
      ),
      HrPresenceFicheStatus.failure when state.failure is NotFoundFailure =>
        EteeloEmptyResult(
          label: l10n.hrAgentNotFoundTitle,
          description: l10n.hrAgentNotFoundMessage,
          medallionIcon: Icons.person_search_outlined,
          fullWidthCard: true,
        ),
      HrPresenceFicheStatus.failure => HrPresenceResultsErrorState(
        failure: state.failure,
        onRetry: () => unawaited(cubit.retry()),
      ),
      HrPresenceFicheStatus.ready when year != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HrPresenceProfileCard(
            agent: year.agent,
            profile: year.profile,
            scopeLabel: l10n.hrPresenceScopeYearLabel(year.schoolYear.name),
          ),
          const SizedBox(height: AppSpacing.lg),
          HrPresenceFicheKpis(kpis: year.kpis, hourly: year.agent.isHourly),
          const SizedBox(height: AppSpacing.lg),
          HrPresenceYearList(
            months: year.months,
            onOpenMonth: (m) => unawaited(cubit.openMonth(m)),
          ),
        ],
      ),
      HrPresenceFicheStatus.ready when month != null && month.classDays == 0 =>
        PresenceHolidayState(
          month: state.month,
          onCurrent: () => unawaited(cubit.goCurrentMonth()),
        ),
      HrPresenceFicheStatus.ready when month != null => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HrPresenceProfileCard(
            agent: month.agent,
            profile: month.profile,
            scopeLabel: dates.formatMonthYear(
              DateTime.parse('${month.month}-01'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          HrPresenceFicheKpis(kpis: month.kpis, hourly: month.agent.isHourly),
          const SizedBox(height: AppSpacing.lg),
          HrPresenceMonthBody(month: month, withTrend: false),
        ],
      ),
      HrPresenceFicheStatus.ready => const EteeloListSkeleton(rowCount: 5),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        toolbar,
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }
}
