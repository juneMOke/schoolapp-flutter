import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_agent_situations.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_agent_navigation.dart';

/// Le rang de l'agent dans le livre d'entrée, et de quoi passer à son voisin
/// — `null` aux extrémités, ou hors du livre.
class PayrollAgentStepper {
  final int index;
  final int count;
  final VoidCallback? previous;
  final VoidCallback? next;

  const PayrollAgentStepper._(this.index, this.count, this.previous, this.next);

  factory PayrollAgentStepper.of(
    BuildContext context,
    PayrollState state, {
    required String agentId,
    required String entryMonth,
  }) {
    final view = state.history.where((v) => v.month == entryMonth).firstOrNull;
    final roster = view == null
        ? const <String>[]
        : PayrollAgentSituations.roster(state.snapshot, view);
    final index = roster.indexOf(agentId);
    VoidCallback? to(int at) => index < 0 || at < 0 || at >= roster.length
        ? null
        : () => PayrollAgentNavigation.step(
            context,
            agentId: roster[at],
            month: entryMonth,
          );
    return PayrollAgentStepper._(
      index,
      index < 0 ? 0 : roster.length,
      to(index - 1),
      to(index + 1),
    );
  }
}
