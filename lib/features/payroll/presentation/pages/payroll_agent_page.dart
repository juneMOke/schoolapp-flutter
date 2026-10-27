import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/keyboard/route_key_shortcut.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/home/presentation/widget/off_shell_top_bar.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/helpers/hr_presence_context.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_agent_navigation.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/agent/payroll_agent_body.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_refresh_shortcut.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que l'adresse donne à la fiche : l'agent, et le livre d'entrée
/// (`?mois-agent=`), qui fixe l'ordre de parcours.
typedef PayrollAgentArgs = ({String agentId, String? month});

/// RH · Paie ▸ Paie ▸ un agent : toute sa situation de paie sur un écran,
/// par-dessus le livre (`/home/paie/{agentId}?mois-agent=AAAA-MM`).
///
/// Son propre [PayrollCubit] sur la même tablette : les gestes du livre
/// (éléments variables, versement, bulletin, profil) s'y branchent tels
/// quels, et le livre du dessous, qui suit la tablette, les voit au retour.
class PayrollAgentPage extends StatelessWidget {
  final PayrollAgentArgs args;
  final VoidCallback? onClosed;

  /// L'écran qui l'a ouverte : le livre, le tableau de bord ou les arriérés.
  final String shellSubMenuId;

  const PayrollAgentPage({
    super.key,
    required this.args,
    this.onClosed,
    this.shellSubMenuId = PayrollAgentNavigation.subMenuId,
  });

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollCubit>(
    create: (_) => getIt<PayrollCubit>()
      ..showMonth(args.month)
      ..load(),
    child: HrClosingNotifier(
      onClosed: onClosed,
      child: PayrollRefreshShortcut(
        child: PayrollAgentScreen(
          agentId: args.agentId,
          entryMonth: args.month,
          shellSubMenuId: shellSubMenuId,
        ),
      ),
    ),
  );
}

class PayrollAgentScreen extends StatelessWidget {
  final String agentId;

  /// `null` : le mois en cours.
  final String? entryMonth;
  final String shellSubMenuId;

  const PayrollAgentScreen({
    super.key,
    required this.agentId,
    required this.entryMonth,
    this.shellSubMenuId = PayrollAgentNavigation.subMenuId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageBackground(
      width: PageContentWidth.wide,
      appBar: OffShellTopBar(
        eyebrow: l10n.menuHrPayroll,
        title: l10n.payrollAgentTitle,
        backTooltip: switch (shellSubMenuId) {
          MenuConstants.hrPayrollDashboardId => l10n.subMenuDashboard,
          MenuConstants.hrPayrollArrearsId => l10n.subMenuPayrollArrears,
          _ => l10n.payrollTabLedger,
        },
        shellSubMenuId: shellSubMenuId,
        onBack: (context) =>
            PayrollAgentNavigation.leave(context, from: shellSubMenuId),
      ),
      child: BlocConsumer<PayrollCubit, PayrollState>(
        listenWhen: (previous, current) =>
            current.notice != null && previous.notice != current.notice,
        listener: (context, state) => showPayrollNotice(
          context,
          state.notice!,
          monthLabel: PayrollLabels.month(
            context,
            PayrollMonth.previous(state.month),
          ),
        ),
        buildWhen: (previous, current) =>
            previous.copyWith(notice: current.notice) != current,
        builder: (context, state) => switch (state.load) {
          PayrollLoad.loading => const EteeloListSkeleton(rowCount: 6),
          PayrollLoad.failure => StaffResultsErrorState(
            failure: state.failure,
            onRetry: context.read<PayrollCubit>().load,
          ),
          PayrollLoad.ready => _ready(context, state),
        },
      ),
    );
  }

  Widget _ready(BuildContext context, PayrollState state) {
    final stepper = PayrollAgentStepper.of(
      context,
      state,
      agentId: agentId,
      entryMonth: entryMonth ?? state.currentMonth,
    );
    return RouteKeyShortcut(
      activators: const [
        SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
      ],
      isEnabled: () => stepper.previous != null,
      onPressed: () => stepper.previous?.call(),
      child: RouteKeyShortcut(
        activators: const [
          SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
        ],
        isEnabled: () => stepper.next != null,
        onPressed: () => stepper.next?.call(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!state.snapshot.hasEverSynced)
              EteeloNotice.warning(
                AppLocalizations.of(context)!.payrollNotYetSynced,
              ),
            PayrollAgentBody(state: state, agentId: agentId, stepper: stepper),
          ],
        ),
      ),
    );
  }
}
