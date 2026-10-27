import 'package:school_app_flutter/features/payroll/domain/services/payroll_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_month_strip.dart';

/// Les mois de la frise, lus sur la tablette : du premier contrat de l'école
/// au mois en cours, chacun avec le statut de sa paie (`null` : aucune).
abstract final class PayrollMonthEntries {
  static List<PayrollMonthEntry> of(PayrollState state) {
    final current = state.currentMonth;
    final first = state.snapshot.firstMonth ?? current;
    final start = first.compareTo(current) > 0 ? current : first;
    final phases = {
      for (final view in state.history)
        if (view.header != null || view.lines.isNotEmpty)
          view.month: view.phase,
    };
    final count = PayrollMonth.between(start, current) + 1;
    return [
      for (var i = 0; i < count; i++)
        (
          month: PayrollMonth.add(start, i),
          phase: phases[PayrollMonth.add(start, i)],
        ),
    ];
  }
}
