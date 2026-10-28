import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_picker.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_month.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_circuit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau du livre : ‹ octobre 2026 › et son statut, puis le circuit.
/// Le mois ouvre le sélecteur de mois des registres RH — plus de frise :
/// le mois se lit une seule fois.
class PayrollLedgerHeader extends StatelessWidget {
  final PayrollState state;

  const PayrollLedgerHeader({super.key, required this.state});

  /// Les douze mois proposés au sélecteur : ceux qui finissent au mois en
  /// cours, ou, pour un mois plus ancien, ceux qui partent de lui ; jamais
  /// avant le premier mois de paie.
  static String firstPickable(PayrollState state) {
    final window = SchoolDayCalendar.addMonths(state.currentMonth, -11);
    final anchor = state.month.compareTo(window) < 0 ? state.month : window;
    final first = state.snapshot.firstMonth;
    return first != null && first.compareTo(anchor) > 0 ? first : anchor;
  }

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<PayrollCubit>();
    final picked = await pickPresenceMonth(
      context,
      month: state.month,
      firstMonth: firstPickable(state),
      lastMonth: state.currentMonth,
    );
    if (picked != null && !cubit.isClosed) cubit.showMonth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final view = state.view;
    return KubaBanner(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          KubaBannerMonth(
            eyebrow: l10n.payrollTabLedger,
            month: state.month,
            status: view == null ? null : PayrollStatusPill(phase: view.phase),
            onPrevious: state.canStepBack ? () => cubit.stepMonth(-1) : null,
            onNext: state.isCurrentMonth ? null : () => cubit.stepMonth(1),
            onCurrent: state.isCurrentMonth ? null : cubit.goCurrentMonth,
            onPick: () => unawaited(_pick(context)),
          ),
          if (view != null) PayrollCircuit(view: view),
        ],
      ),
    );
  }
}
