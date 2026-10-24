import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_args.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/agent/hr_presence_agent_month_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/agent/hr_presence_agent_identity.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/agent/hr_presence_agent_kpis.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/agent/hr_presence_agent_toolbar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/agent/hr_presence_month_body.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/hr_fiche_location.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/states/hr_presence_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// RH · Présences ▸ Tableau de bord ▸ un agent (spec §5) : son mois, lu au
/// serveur (route 2), par-dessus le tableau de bord qui l'a ouvert —
/// `/home/rh-presences-tableau-de-bord/{agentId}?mois=AAAA-MM`. La flèche
/// rend le tableau de bord tel qu'on l'a quitté, période comprise.
///
/// Un écran distinct de la vue mensuelle de la fiche individuelle (§12),
/// même s'il lit la même route.
class HrPresenceAgentPage extends StatelessWidget {
  /// Le mois affiché, `AAAA-MM`.
  static const monthParam = 'mois';

  final HrPresenceAgentArgs args;

  /// Prévient l'écran qui l'a ouvert, à sa disparition.
  final VoidCallback? onClosed;

  const HrPresenceAgentPage({super.key, required this.args, this.onClosed});

  /// Ouvre [agentId] sur [month] par-dessus le tableau de bord, et se
  /// termine quand la page se referme.
  static Future<void> open(
    BuildContext context, {
    required String agentId,
    required String month,
  }) => HrAgentIntent.open(
    context,
    subMenuId: MenuConstants.hrPresenceDashboardId,
    agentId: agentId,
    query: {monthParam: month},
  );

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => getIt<HrPresenceAgentMonthCubit>(
      param1: (
        agentId: args.agentId,
        month: args.month,
        yearStart: args.yearStart ?? _yearStart(context),
      ),
    )..load(),
    child: _ClosingNotifier(
      onClosed: onClosed,
      child: const HrPresenceAgentScreen(),
    ),
  );
}

/// L'ouverture de l'année, si le contexte la connaît déjà.
DateTime? _yearStart(BuildContext context) {
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

/// Appelle [onClosed] quand la page disparaît, quelle que soit la sortie.
class _ClosingNotifier extends StatefulWidget {
  final VoidCallback? onClosed;
  final Widget child;

  const _ClosingNotifier({required this.onClosed, required this.child});

  @override
  State<_ClosingNotifier> createState() => _ClosingNotifierState();
}

class _ClosingNotifierState extends State<_ClosingNotifier> {
  @override
  void dispose() {
    widget.onClosed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class HrPresenceAgentScreen extends StatelessWidget {
  const HrPresenceAgentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceAgentMonthCubit>();
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(cubit.retry()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        // Posée hors du BlocBuilder : la sortie reste offerte pendant la
        // lecture comme après un échec.
        appBar: OffShellTopBar(
          eyebrow: l10n.hrPresenceEyebrow,
          title: l10n.hrPresenceAgentTitle,
          backTooltip: l10n.hrPresenceAllAgents,
          shellSubMenuId: MenuConstants.hrPresenceDashboardId,
        ),
        child:
            BlocBuilder<HrPresenceAgentMonthCubit, HrPresenceAgentMonthState>(
              builder: (context, state) => _body(context, l10n, cubit, state),
            ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    HrPresenceAgentMonthCubit cubit,
    HrPresenceAgentMonthState state,
  ) {
    final dates = MaterialLocalizations.of(context);
    final data = state.data;
    final Widget content = switch (state.status) {
      HrPresenceAgentMonthStatus.loading => const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloKpiBandSkeleton(count: 4),
          SizedBox(height: AppSpacing.lg),
          EteeloListSkeleton(rowCount: 5),
        ],
      ),
      HrPresenceAgentMonthStatus.failure
          when state.failure is NotFoundFailure =>
        EteeloEmptyResult(
          label: l10n.hrAgentNotFoundTitle,
          description: l10n.hrAgentNotFoundMessage,
          medallionIcon: Icons.person_search_outlined,
          fullWidthCard: true,
        ),
      HrPresenceAgentMonthStatus.failure => HrPresenceResultsErrorState(
        failure: state.failure,
        onRetry: () => unawaited(cubit.retry()),
      ),
      HrPresenceAgentMonthStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HrPresenceAgentIdentity(
            agent: data!.agent,
            presenceRatePct: data.kpis.presenceRatePct,
          ),
          const SizedBox(height: AppSpacing.lg),
          HrPresenceAgentKpis(month: data),
          const SizedBox(height: AppSpacing.lg),
          HrPresenceMonthBody(month: data),
          const SizedBox(height: AppSpacing.lg),
          _Actions(agentId: state.agentId, month: state.month),
        ],
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrPersonnelHeader(
          subtitle: l10n.hrPresenceDashboardSubtitle(
            dates.formatMonthYear(DateTime.parse('${state.month}-01')),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        HrPresenceAgentToolbar(state: state),
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final String agentId;
  final String month;

  const _Actions({required this.agentId, required this.month});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        EteeloButton.secondary(
          label: l10n.hrPresenceAgentOpenFiche,
          icon: Icons.badge_outlined,
          // Dans la coquille, par son adresse : le détail est poussé
          // par-dessus le tableau de bord, la fiche par-dessus sa liste.
          onPressed: () => context.go(
            Uri(
              path: AppRoutesNames.hrPersonnelAgentPath(
                subMenuId: MenuConstants.hrPresenceFicheId,
                agentId: agentId,
              ),
              queryParameters: {HrFicheLocation.monthParam: month},
            ).toString(),
          ),
          fullWidth: false,
        ),
        // Le montant et la paie : à qui lit la paie seulement (E2).
        if (PermissionGate.allowsAccess(context, kPayrollReadAccess))
          EteeloButton.secondary(
            label: l10n.hrPresenceAgentOpenPayroll,
            icon: Icons.payments_outlined,
            // Dans la coquille, par son adresse : la page de l'agent est
            // poussée par-dessus, hors de la navigation du menu.
            onPressed: () => context.go(
              AppRoutesNames.homeSubMenuPath(MenuConstants.hrPayrollId),
            ),
            fullWidth: false,
          ),
      ],
    );
  }
}
