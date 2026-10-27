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
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/fiche/hr_presence_fiche_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/agent/hr_presence_month_body.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_profile_evidence.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_fiche_agent_scope.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_fiche_kpis.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_fiche_sheet.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_profile_card.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/fiche/hr_presence_year_list.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/states/hr_presence_results_error_state.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_context.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Présences ▸ Fiche individuelle ▸ un agent (spec §12) : son profil,
/// en vue mensuelle (route 2) ou annuelle (route 3), par-dessus la liste —
/// `/home/rh-presences-fiche/{agentId}?vue-agent=an` ou `?mois-agent=AAAA-MM`
/// — sous le Récapitulatif quand c'est lui qui l'ouvre, pour qu'un F5 la
/// rebâtisse sur le bon écran.
class HrPresenceFicheAgentPage extends StatelessWidget {
  final HrPresenceFicheArgs args;
  final VoidCallback? onClosed;

  /// L'écran qui l'a ouverte : la liste de la fiche, ou le récapitulatif.
  final String shellSubMenuId;

  const HrPresenceFicheAgentPage({
    super.key,
    required this.args,
    this.onClosed,
    this.shellSubMenuId = MenuConstants.hrPresenceFicheId,
  });

  /// Ouvre la fiche de [agentId] sur la portée de l'écran qui l'ouvre, et se
  /// termine quand elle se referme.
  static Future<void> open(
    BuildContext context, {
    required String agentId,
    required bool yearly,
    required String month,
    String fromSubMenuId = MenuConstants.hrPresenceFicheId,
  }) => HrAgentIntent.open(
    context,
    subMenuId: fromSubMenuId,
    agentId: agentId,
    query: yearly
        ? {HrAgentAddress.viewParam: HrAgentAddress.yearValue}
        : {HrAgentAddress.monthParam: month},
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => getIt<HrPresenceFicheCubit>(
      param1: (
        agentId: args.agentId,
        yearly: args.yearly,
        month: args.month,
        yearStart: args.yearStart ?? HrPresenceContext.yearStart(context),
      ),
    )..load(),
    child: HrClosingNotifier(
      onClosed: onClosed,
      child: HrPresenceFicheAgentScreen(shellSubMenuId: shellSubMenuId),
    ),
  );
}

class HrPresenceFicheAgentScreen extends StatelessWidget {
  final String shellSubMenuId;

  const HrPresenceFicheAgentScreen({
    super.key,
    this.shellSubMenuId = MenuConstants.hrPresenceFicheId,
  });

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
          backTooltip: shellSubMenuId == MenuConstants.hrPresenceRecapId
              ? l10n.subMenuHrPresenceRecap
              : l10n.hrPresenceStaffList,
          shellSubMenuId: shellSubMenuId,
          onBack: (context) =>
              HrAgentAddress.leave(context, subMenuId: shellSubMenuId),
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
    Widget scope({required bool framed}) =>
        HrPresenceFicheAgentScope(state: state, cubit: cubit, framed: framed);
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
          description: l10n.hrPresenceAgentNotFoundMessage,
          medallionIcon: Icons.person_search_outlined,
          fullWidthCard: true,
        ),
      HrPresenceFicheStatus.failure => HrPresenceResultsErrorState(
        failure: state.failure,
        onRetry: () => unawaited(cubit.retry()),
      ),
      HrPresenceFicheStatus.ready
          when year != null && year.schoolYear == null =>
        EteeloEmptyResult(
          label: l10n.hrPresenceNoYearTitle,
          description: l10n.hrPresenceNoYearMessage,
          medallionIcon: Icons.event_busy_outlined,
          fullWidthCard: true,
        ),
      HrPresenceFicheStatus.ready when year != null => HrPresenceFicheSheet(
        header: HrPresenceProfileCard(
          embedded: true,
          agent: year.agent,
          profile: year.profile,
          scopeLabel: l10n.hrPresenceScopeYearLabel(year.schoolYear!.name),
          evidence: HrPresenceProfileEvidence.of(l10n, year.profile, year.kpis),
          coverage: HrPresenceProfileEvidence.coverage(
            l10n,
            year.kpis,
            classDays: year.months.fold(0, (sum, m) => sum + m.classDays),
            hourly: year.agent.isHourly,
          ),
        ),
        scope: scope(framed: false),
        kpis: HrPresenceFicheKpis(kpis: year.kpis, hourly: year.agent.isHourly),
        body: HrPresenceYearList(
          months: year.months,
          total: year.kpis,
          totalProfile: year.profile,
          onOpenMonth: (m) => unawaited(cubit.openMonth(m)),
        ),
      ),
      HrPresenceFicheStatus.ready when month != null && month.classDays == 0 =>
        PresenceHolidayState(
          month: state.month,
          onCurrent: () => unawaited(cubit.goCurrentMonth()),
        ),
      HrPresenceFicheStatus.ready when month != null => HrPresenceFicheSheet(
        header: HrPresenceProfileCard(
          embedded: true,
          agent: month.agent,
          profile: month.profile,
          scopeLabel: dates.formatMonthYear(
            DateTime.parse('${month.month}-01'),
          ),
          evidence: HrPresenceProfileEvidence.of(
            l10n,
            month.profile,
            month.kpis,
          ),
          coverage: HrPresenceProfileEvidence.coverage(
            l10n,
            month.kpis,
            classDays: month.classDays,
            hourly: month.agent.isHourly,
          ),
        ),
        scope: scope(framed: false),
        kpis: HrPresenceFicheKpis(
          kpis: month.kpis,
          hourly: month.agent.isHourly,
        ),
        body: HrPresenceMonthBody(month: month, withTrend: false),
      ),
      HrPresenceFicheStatus.ready => const EteeloListSkeleton(rowCount: 5),
    };
    // Les données là, la feuille porte aussi la portée ; sinon la portée
    // reste dans sa carte, au-dessus de l'état (chargement, erreur, vide).
    if (content is HrPresenceFicheSheet) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scope(framed: true),
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }
}
