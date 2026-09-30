import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_circuit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_month_nav.dart';

/// ‹ octobre 2026 › · statut · circuit — le mois affiché une seule fois,
/// partagé par le livre et les bulletins.
class PayrollLedgerHeader extends StatelessWidget {
  final PayrollState state;
  final bool withCircuit;

  const PayrollLedgerHeader({
    super.key,
    required this.state,
    this.withCircuit = true,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PayrollCubit>();
    final view = state.view;
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StaffMonthNav(
              month: state.month,
              isCurrent: state.isCurrentMonth,
              onPrevious: state.canStepBack ? () => cubit.stepMonth(-1) : null,
              onNext: () => cubit.stepMonth(1),
              onCurrent: cubit.goCurrentMonth,
            ),
            if (view != null) PayrollStatusPill(phase: view.phase),
          ],
        ),
        if (withCircuit && view != null) PayrollCircuit(view: view),
      ],
    );
  }
}
