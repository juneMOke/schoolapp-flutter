import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_refresh_shortcut.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_month_location.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Paie ▸ Paie — le livre du mois ; toucher un agent ouvre sa fiche
/// (situation, calcul, bulletin). Les avances, les arriérés et le barème ont
/// leur sous-module.
///
/// Lecture 100 % locale, écriture 100 % file d'envoi : la tablette calcule le
/// livre pour l'afficher, le serveur le recalcule pour le figer.
class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollCubit>(
    create: (_) => getIt<PayrollCubit>()..load(),
    child: const PayrollMonthLocation(
      child: PayrollRefreshShortcut(child: PayrollScreen()),
    ),
  );
}

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    width: PageContentWidth.wide,
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
          EteeloNotice.warning(
            AppLocalizations.of(context)!.payrollNotYetSynced,
          ),
        PayrollLedgerView(state: state),
      ],
    );
  }
}
