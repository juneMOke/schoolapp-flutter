import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/dashboard/payroll_dashboard.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/dashboard/payroll_dashboard_cubit.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_choice_chips.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_advances_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_arrears_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_kpis.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_split_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_dashboard_staff_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_month_chart_card.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/dashboard/payroll_side_by_side.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'écran prêt, du plus synthétique au plus détaillé — le modèle de la
/// Boutique et de RH · Présences : chiffres → temps → répartition → prêts et
/// arriérés → salariés.
class PayrollDashboardContent extends StatelessWidget {
  final PayrollDashboardState state;
  final PayrollDashboard dashboard;
  final PayrollDashboardCurrency section;
  final VoidCallback onManageAdvances;
  final VoidCallback onSettleArrears;

  const PayrollDashboardContent({
    super.key,
    required this.state,
    required this.dashboard,
    required this.section,
    required this.onManageAdvances,
    required this.onSettleArrears,
  });

  static const double _gap = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PayrollDashboardCubit>();
    final currencies = [for (final c in dashboard.currencies) c.currency];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currencies.length > 1) ...[
          PayrollChoiceChips<String>(
            values: currencies,
            selected: section.currency,
            label: (code) => code,
            onSelected: cubit.selectCurrency,
          ),
          const SizedBox(height: _gap),
        ],
        PayrollDashboardKpis(dashboard: dashboard, section: section),
        if (!dashboard.tracked) ...[
          const SizedBox(height: _gap),
          EteeloNotice.warning(l10n.payrollDashNotTracked),
        ],
        const SizedBox(height: _gap),
        PayrollMonthChartCard(
          dashboard: dashboard,
          currency: section.currency,
          onOpenMonth: (month) => unawaited(cubit.showMonth(month)),
        ),
        const SizedBox(height: _gap),
        PayrollDashboardSplitCard(dashboard: dashboard, section: section),
        const SizedBox(height: _gap),
        PayrollSideBySide(
          first: PayrollDashboardAdvancesCard(
            advances: dashboard.advances,
            onManage: onManageAdvances,
          ),
          second: PayrollDashboardArrearsCard(
            arrears: dashboard.arrears,
            currency: section.currency,
            onSettle: onSettleArrears,
          ),
        ),
        if (dashboard.tracked) ...[
          const SizedBox(height: _gap),
          PayrollDashboardStaffCard(state: state, section: section),
        ],
      ],
    );
  }
}
