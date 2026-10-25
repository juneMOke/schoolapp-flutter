import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/advances/payroll_advances_tab.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payroll_notices.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Paie ▸ Avances & prêts — les demandes dans le circuit de dépense, le
/// registre des avances décaissées et leur échéancier, sur le même cubit que
/// la Paie (factory : un par page).
class PayrollAdvancesPage extends StatelessWidget {
  const PayrollAdvancesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<PayrollCubit>(
    create: (_) => getIt<PayrollCubit>()..load(),
    child: const PayrollAdvancesScreen(),
  );
}

class PayrollAdvancesScreen extends StatelessWidget {
  const PayrollAdvancesScreen({super.key});

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
      builder: (context, state) => switch (state.load) {
        PayrollLoad.failure => StaffResultsErrorState(
          failure: state.failure,
          onRetry: context.read<PayrollCubit>().load,
        ),
        PayrollLoad.loading => const EteeloListSkeleton(rowCount: 8),
        PayrollLoad.ready => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!state.snapshot.hasEverSynced)
              EteeloNotice.warning(
                AppLocalizations.of(context)!.payrollNotYetSynced,
              ),
            PayrollAdvancesTab(state: state),
          ],
        ),
      },
    ),
  );
}
