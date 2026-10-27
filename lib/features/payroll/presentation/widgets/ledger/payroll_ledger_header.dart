import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_nav.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_month_entries.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_circuit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_month_strip.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';

/// ‹ octobre 2026 › · statut · circuit, puis la frise des mois — le mois
/// affiché une seule fois.
class PayrollLedgerHeader extends StatelessWidget {
  final PayrollState state;

  const PayrollLedgerHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PayrollCubit>();
    final view = state.view;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PresenceMonthNav(
                  month: state.month,
                  isCurrent: state.isCurrentMonth,
                  onPrevious: state.canStepBack
                      ? () => cubit.stepMonth(-1)
                      : null,
                  onNext: () => cubit.stepMonth(1),
                  onCurrent: cubit.goCurrentMonth,
                ),
                if (view != null) PayrollStatusPill(phase: view.phase),
              ],
            ),
            if (view != null) PayrollCircuit(view: view),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        PayrollMonthStrip(
          months: PayrollMonthEntries.of(state),
          selected: state.month,
          onSelect: cubit.showMonth,
        ),
      ],
    );
  }
}
