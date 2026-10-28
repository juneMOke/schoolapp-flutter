import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/arrears/payroll_arrears_agent_dialog.dart';

/// La fiche d'arriérés d'un agent, puis son geste — verser (réparti du mois
/// le plus ancien au plus récent) ou lever la priorité. Le registre des
/// arriérés et la fiche de paie d'un agent l'ouvrent pareil.
class PayrollArrearsActions {
  final BuildContext context;

  const PayrollArrearsActions(this.context);

  Future<void> open(PayrollArrearsAgent agent, String currentMonth) async {
    final cubit = context.read<PayrollCubit>();
    final state = cubit.state;
    final name =
        state.snapshot.member(agent.staffMemberId)?.fullName ??
        agent.staffMemberId;
    final outcome = await PayrollArrearsAgentDialog.show(
      context,
      PayrollArrearsAgentDialog(
        name: name,
        snapshot: state.snapshot,
        agent: agent,
        currentMonth: currentMonth,
        canWrite: PermissionGate.allows(context, kPayrollWriteAccess.requires),
        profile:
            state.snapshot.profiles[agent.staffMemberId] ??
            StaffPayProfile.empty(agent.staffMemberId),
      ),
    );
    if (outcome == null || !context.mounted) return;
    final prioritize = outcome.prioritize;
    if (prioritize != null) {
      for (final arrear in agent.months) {
        if (arrear.prioritized == prioritize) continue;
        await cubit.perform(
          (commands) =>
              commands.setArrearsPriority(arrear, prioritized: prioritize),
        );
        if (!context.mounted) return;
      }
      return;
    }
    final proof = outcome.proof;
    if (proof == null) return;
    // Le registre a pu bouger pendant la saisie (un pull, un autre poste) :
    // la répartition se refait sur l'agent tel qu'il est maintenant.
    final snapshot = cubit.state.snapshot;
    final fresh = PayrollArrears.of(
      snapshot,
      currentMonth: currentMonth,
    ).where((a) => a.staffMemberId == agent.staffMemberId).firstOrNull;
    if (fresh == null) return;
    await cubit.perform(
      (commands) => commands.payArrears(
        snapshot,
        fresh,
        currency: outcome.currency,
        amountInCents: outcome.amountInCents,
        proof: proof,
        name: name,
      ),
    );
  }
}
