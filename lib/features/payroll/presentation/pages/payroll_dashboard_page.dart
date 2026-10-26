import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_body.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_month_location.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// RH · Paie ▸ Tableau de bord (spec TB) — combien la paie devait coûter,
/// combien il faut réellement payer, combien est payé ou non. Calculé sur la
/// tablette depuis les lignes du livre ; seul le PDF nominatif vient du
/// serveur, sur les mêmes paramètres.
class PayrollDashboardPage extends StatelessWidget {
  const PayrollDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollCubit>(
    create: (_) => getIt<PayrollCubit>()..load(),
    child: const PayrollMonthLocation(child: PayrollDashboardScreen()),
  );
}

class PayrollDashboardScreen extends StatelessWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    width: PageContentWidth.wide,
    child: BlocConsumer<PayrollCubit, PayrollState>(
      listenWhen: (previous, current) =>
          current.notice != null && previous.notice != current.notice,
      listener: (context, state) => showPayrollNotice(
        context,
        state.notice!,
        monthLabel: PayrollLabels.month(context, state.month),
      ),
      buildWhen: (previous, current) =>
          previous.copyWith(notice: current.notice) != current,
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        switch (state.load) {
          case PayrollLoad.failure:
            return StaffResultsErrorState(
              failure: state.failure,
              onRetry: context.read<PayrollCubit>().load,
            );
          case PayrollLoad.loading:
            return const EteeloListSkeleton(rowCount: 8);
          case PayrollLoad.ready:
            break;
        }
        final view = state.view;
        if (state.snapshot.members.isEmpty || view == null) {
          return EteeloEmptyResult(
            label: l10n.payrollDashNoStaff,
            medallionIcon: Icons.groups_outlined,
            primaryAction: PermissionGate.allows(context, [Perm.hrStaffRead])
                ? EteeloButton.secondary(
                    label: l10n.payrollOpenStaffFile,
                    onPressed: () => context.go(
                      AppRoutesNames.homeSubMenuPath(
                        MenuConstants.hrStaffFileId,
                      ),
                    ),
                    fullWidth: false,
                  )
                : null,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!state.snapshot.hasEverSynced)
              EteeloNotice.warning(l10n.payrollNotYetSynced),
            PayrollDashboardBody(state: state, view: view),
          ],
        );
      },
    ),
  );
}
