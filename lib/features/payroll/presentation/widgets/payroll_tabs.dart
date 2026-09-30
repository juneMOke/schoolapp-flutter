import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_fingerprint.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_card_tabs.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre onglets de la paie, en cartes comme ceux du Pointage.
class PayrollTabs extends StatelessWidget {
  final PayrollState state;
  final ValueChanged<PayrollTab> onSelect;

  const PayrollTabs({super.key, required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = state.view;
    final net = PayrollLabels.perCurrency([
      for (final total in view?.totals ?? const <PayrollTotal>[])
        (total.netInCents, total.currency),
    ]).join(' · ');
    final ongoing = state.snapshot.advances
        .where((advance) => advance.isOngoing)
        .length;
    final months = state.snapshot.headers.length;
    return StaffCardTabs<PayrollTab>(
      active: state.tab,
      onSelect: onSelect,
      tabs: [
        StaffCardTab(
          id: PayrollTab.ledger,
          icon: Icons.receipt_long_outlined,
          title: l10n.payrollTabLedger,
          subtitle: l10n.payrollTabLedgerSubtitle(net),
          badge: view == null
              ? null
              : PayrollTone.of(
                  view.phase,
                ).badge(PayrollLabels.phase(l10n, view.phase)),
        ),
        StaffCardTab(
          id: PayrollTab.payslips,
          icon: Icons.description_outlined,
          title: l10n.payrollTabPayslips,
          subtitle: l10n.payrollTabPayslipsSubtitle,
        ),
        StaffCardTab(
          id: PayrollTab.advances,
          icon: Icons.volunteer_activism_outlined,
          title: l10n.payrollTabAdvances,
          subtitle: ongoing == 0
              ? l10n.payrollTabAdvancesNone
              : l10n.payrollTabAdvancesOngoing(ongoing),
        ),
        StaffCardTab(
          id: PayrollTab.history,
          icon: Icons.history,
          title: l10n.payrollTabHistory,
          subtitle: l10n.payrollTabHistorySubtitle(months),
        ),
      ],
    );
  }
}
