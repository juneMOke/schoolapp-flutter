import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_content.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_header.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_location.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/states/payroll_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// RH · Paie ▸ Tableau de bord — **en ligne** (P9), comme RH · Personnel :
/// chiffres, mois par mois, liste et PDF lus au serveur sur les mêmes
/// paramètres (règle n° 14). Hors ligne, l'erreur réseau s'affiche ; la Paie,
/// les avances, les arriérés et le barème restent lisibles hors ligne.
class PayrollDashboardPage extends StatelessWidget {
  const PayrollDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollDashboardCubit>(
    create: (_) => getIt<PayrollDashboardCubit>()..load(),
    child: const PayrollDashboardLocation(child: PayrollDashboardScreen()),
  );
}

class PayrollDashboardScreen extends StatelessWidget {
  const PayrollDashboardScreen({super.key});

  void _go(BuildContext context, String subMenuId) =>
      context.go(AppRoutesNames.homeSubMenuPath(subMenuId));

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PayrollDashboardCubit>();
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(cubit.refresh()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        child: BlocConsumer<PayrollDashboardCubit, PayrollDashboardState>(
          listenWhen: (previous, current) =>
              current.refreshFailureSeq != previous.refreshFailureSeq,
          listener: (context, state) {
            final l10n = AppLocalizations.of(context)!;
            if (state.refreshFailure is NetworkFailure) {
              AppSnackBar.showWarning(context, l10n.payrollDashRefreshOffline);
            } else {
              AppSnackBar.showError(context, l10n.payrollDashRefreshFailed);
            }
          },
          buildWhen: (previous, current) =>
              previous.copyWith(
                refreshFailure: () => current.refreshFailure,
                refreshFailureSeq: current.refreshFailureSeq,
              ) !=
              current,
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PayrollDashboardHeader(
                state: state,
                onOpenPayroll: () => _go(context, MenuConstants.hrPayrollId),
              ),
              const SizedBox(height: AppSpacing.lg),
              _body(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PayrollDashboardState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollDashboardCubit>();
    final dashboard = state.dashboard;
    final section = state.section;
    switch (state.load) {
      case PayrollDashboardLoad.loading:
        return const PayrollDashboardSkeleton();
      case PayrollDashboardLoad.failure:
        return PayrollResultsErrorState(
          failure: state.failure,
          onRetry: () => unawaited(cubit.refresh()),
        );
      case PayrollDashboardLoad.ready:
        break;
    }
    if (dashboard == null || section == null || dashboard.isEmpty) {
      return EteeloEmptyResult(
        label: l10n.payrollDashNoPayroll,
        medallionIcon: Icons.event_busy_outlined,
        primaryAction: state.isCurrentMonth
            ? EteeloButton.secondary(
                label: l10n.payrollDashPrepare,
                onPressed: () => _go(context, MenuConstants.hrPayrollId),
                fullWidth: false,
              )
            : EteeloButton.secondary(
                label: l10n.payrollDashCurrentMonth,
                onPressed: () => unawaited(cubit.showMonth(null)),
                fullWidth: false,
              ),
      );
    }
    return PayrollDashboardContent(
      state: state,
      dashboard: dashboard,
      section: section,
      onManageAdvances: () => _go(context, MenuConstants.hrPayrollAdvancesId),
      onSettleArrears: () => _go(context, MenuConstants.hrPayrollArrearsId),
    );
  }
}
