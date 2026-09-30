import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_header.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_panel.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les bulletins du mois : l'agent choisi, sa feuille, et le panneau de
/// diffusion à côté — ou dessous sur un écran étroit.
class PayrollPayslipsTab extends StatelessWidget {
  final PayrollState state;

  const PayrollPayslipsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final view = state.view;
    final lines = view?.lines ?? const [];
    final header = PayrollLedgerHeader(state: state, withCircuit: false);
    if (view == null || lines.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: AppSpacing.lg),
          EteeloEmptyResult(
            label: l10n.payrollPayslipEmpty,
            medallionIcon: Icons.description_outlined,
          ),
        ],
      );
    }
    final wanted = state.payslipMemberId;
    final found = lines.indexWhere((l) => l.staffMemberId == wanted);
    final index = found < 0 ? 0 : found;
    final line = lines[index];
    final sheet = PayrollPayslipSheet(
      content: PayrollPayslipContent.of(
        context,
        snapshot: state.snapshot,
        view: view,
        line: line,
      ),
    );
    final panel = PayrollPayslipPanel(
      state: state,
      line: line,
      index: index,
      count: lines.length,
      onStep: (i) => cubit.selectPayslip(lines[i].staffMemberId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.md),
        EteeloSelectInput<String>(
          label: l10n.payrollColAgent,
          value: line.staffMemberId,
          items: [
            for (final l in lines)
              EteeloSelectItem(
                value: l.staffMemberId,
                label:
                    state.snapshot.member(l.staffMemberId)?.fullName ??
                    l.staffMemberId,
              ),
          ],
          onChanged: (id) {
            if (id != null) cubit.selectPayslip(id);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth >= AppDimensions.payrollPayslipWideBreakpoint
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Center(child: sheet)),
                    const SizedBox(width: AppSpacing.lg),
                    SizedBox(
                      width: AppDimensions.payrollPayslipPanelWidth,
                      child: panel,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    panel,
                    const SizedBox(height: AppSpacing.lg),
                    sheet,
                  ],
                ),
        ),
      ],
    );
  }
}
