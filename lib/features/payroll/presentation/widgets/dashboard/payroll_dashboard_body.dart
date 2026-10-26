import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_state.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_advances_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_arrears_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_forecast_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_paid_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_staff_section.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_month_columns.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/ledger/payroll_ledger_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Le tableau de bord d'un mois prêt : prévu et réel, payé et non payé, prêts
/// et arriérés, puis ce que chaque salarié perçoit. Une devise à la fois —
/// celle qui paie le plus d'agents, au choix si le mois en compte deux.
class PayrollDashboardBody extends StatefulWidget {
  final PayrollState state;
  final PayrollMonthView view;

  const PayrollDashboardBody({
    super.key,
    required this.state,
    required this.view,
  });

  @override
  State<PayrollDashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<PayrollDashboardBody> {
  String? _currency;

  void _go(String subMenuId) =>
      context.go(AppRoutesNames.homeSubMenuPath(subMenuId));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollCubit>();
    final state = widget.state;
    final view = widget.view;
    final currencies = PayrollDashboard.currenciesOf(view);
    final currency = currencies.contains(_currency)
        ? _currency!
        : currencies.isEmpty
        ? state.snapshot.settings.firstCurrency
        : currencies.first;
    final validated = view.header?.status == PayrollStatus.validated;
    final arrears = PayrollArrears.of(
      state.snapshot,
      currentMonth: state.currentMonth,
    );
    final prioritized = view.month == state.currentMonth
        ? [
            for (final agent in arrears)
              for (final arrear in agent.months)
                if (arrear.prioritized && arrear.currency == currency)
                  arrear.dueInCents,
          ].fold(0, (sum, cents) => sum + cents)
        : 0;
    final columns = [
      for (final month in state.history.reversed)
        PayrollMonthColumn(
          month.month,
          PayrollDashboard.progressOf(month, currency),
        ),
    ];
    final figures = PayrollDashboard.forecastOf(view, currency);
    final settings = state.snapshot.settings;
    final forecast = PayrollDashboardForecastCard(
      view: view,
      forecast: figures,
      currency: currency,
      prioritizedArrearsInCents: prioritized,
      employerChargesInCents: settings.wideSettingsServed
          ? PayrollDashboard.employerChargesOf(figures, settings)
          : null,
    );
    final paid = PayrollDashboardPaidCard(
      progress: PayrollDashboard.progressOf(view, currency),
      validated: validated,
      currency: currency,
      columns: columns,
      month: view.month,
      onOpenMonth: cubit.openMonth,
      onPrepare: () => _go(MenuConstants.hrPayrollId),
    );
    final advances = PayrollDashboardAdvancesCard(
      snapshot: state.snapshot,
      view: view,
      onManage: () => _go(MenuConstants.hrPayrollAdvancesId),
    );
    final arrearsCard = PayrollDashboardArrearsCard(
      snapshot: state.snapshot,
      agents: arrears,
      currency: currency,
      onSettle: () => _go(MenuConstants.hrPayrollArrearsId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PayrollLedgerHeader(
          state: state,
          withCircuit: false,
          trailing: EteeloButton.secondary(
            label: l10n.payrollDashOpenPayroll,
            icon: Icons.receipt_long_outlined,
            onPressed: () => _go(MenuConstants.hrPayrollId),
            fullWidth: false,
          ),
        ),
        if (currencies.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          PayrollChoiceChips<String>(
            values: currencies,
            selected: currency,
            label: (code) => code,
            onSelected: (code) => setState(() => _currency = code),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (view.lines.isEmpty)
          EteeloEmptyResult(
            label: l10n.payrollDashNoPayroll,
            medallionIcon: Icons.event_busy_outlined,
            primaryAction: state.isCurrentMonth
                ? null
                : EteeloButton.secondary(
                    label: l10n.payrollDashCurrentMonth,
                    onPressed: cubit.goCurrentMonth,
                    fullWidth: false,
                  ),
          )
        else if (!PayrollDashboard.isTracked(view)) ...[
          forecast,
          const SizedBox(height: AppSpacing.lg),
          EteeloNotice.warning(l10n.payrollDashNotTracked),
        ] else ...[
          _pair(forecast, paid),
          const SizedBox(height: AppSpacing.lg),
          _pair(advances, arrearsCard),
          const SizedBox(height: AppSpacing.lg),
          PayrollDashboardStaffSection(
            month: view.month,
            rows: PayrollDashboard.rowsOf(view, arrears),
            snapshot: state.snapshot,
            validated: validated,
          ),
        ],
      ],
    );
  }

  /// Deux cartes côte à côte dès qu'elles tiennent, l'une sous l'autre sinon.
  static Widget _pair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth >= AppBreakpoints.sideBySideMin
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: second),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              const SizedBox(height: AppSpacing.lg),
              second,
            ],
          ),
  );
}
