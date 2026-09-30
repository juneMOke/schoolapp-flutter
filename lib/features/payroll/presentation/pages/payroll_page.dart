import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_advances_tab.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/history/payroll_history_tab.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_tab.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_tabs.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslips_tab.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ressources humaines ▸ Paie — le livre du mois, les bulletins, les avances
/// et l'historique.
///
/// Lecture 100 % locale, écriture 100 % file d'envoi : la tablette calcule le
/// livre pour l'afficher, le serveur le recalcule pour le figer.
class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollCubit>(
    create: (_) => getIt<PayrollCubit>()..load(),
    child: const PayrollScreen(),
  );
}

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
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
      builder: _body,
    ),
  );

  Widget _body(BuildContext context, PayrollState state) {
    final cubit = context.read<PayrollCubit>();
    switch (state.load) {
      case PayrollLoad.failure:
        return StaffResultsErrorState(
          failure: state.failure,
          onRetry: cubit.load,
        );
      case PayrollLoad.loading:
        return const EteeloListSkeleton(rowCount: 8);
      case PayrollLoad.ready:
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.snapshot.hasEverSynced)
          StaffNotice.warning(
            AppLocalizations.of(context)!.payrollNotYetSynced,
          ),
        PayrollTabs(state: state, onSelect: cubit.setTab),
        const SizedBox(height: AppSpacing.lg),
        switch (state.tab) {
          PayrollTab.ledger => PayrollLedgerTab(state: state),
          PayrollTab.payslips => PayrollPayslipsTab(state: state),
          PayrollTab.advances => PayrollAdvancesTab(state: state),
          PayrollTab.history => PayrollHistoryTab(state: state),
        },
      ],
    );
  }
}
