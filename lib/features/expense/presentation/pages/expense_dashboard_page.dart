import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_dashboard_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_navigation.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_period_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_period_bar.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_section_note.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_breakdown_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_dashboard_kpi_band.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_evolution_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_insights_row.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_top_types_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/states/expense_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Dépenses ▸ Tableau de bord — ce que l'école décaisse : total de la période,
/// impayés, évolution et postes les plus coûteux. Même liste locale et même
/// période que le registre : basculer d'écran compare, il ne recommence pas.
class ExpenseDashboardPage extends StatelessWidget {
  const ExpenseDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ExpenseDashboardCubit>(
    create: (_) => getIt<ExpenseDashboardCubit>()..load(),
    child: const ExpenseDashboardView(),
  );
}

class ExpenseDashboardView extends StatelessWidget {
  const ExpenseDashboardView({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    child: BlocBuilder<ExpenseDashboardCubit, ExpenseDashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.view != curr.view ||
          prev.period != curr.period ||
          prev.snapshot != curr.snapshot ||
          prev.failure != curr.failure,
      builder: _body,
    ),
  );

  Widget _body(BuildContext context, ExpenseDashboardState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ExpenseDashboardCubit>();
    final failure = state.failure;
    if (state.status == ExpenseLoadStatus.failure && failure != null) {
      return ExpenseResultsErrorState(failure: failure, onRetry: cubit.load);
    }
    final view = state.view;
    final label = ExpensePeriodLabel.of(context, state.period, view.range);
    void openRegister() =>
        openExpenseRegister(context, title: l10n.subMenuExpenseRegister);
    // Sous le mois, le vide s'élargit d'abord ; à partir du mois, il n'y a
    // plus rien à élargir — on va au registre.
    final widen = state.period.canWidenToMonth;
    final registerLabel = l10n.expenseOpenRegister;
    const registerIcon = Icons.receipt_long_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpenseCard(
          child: ExpensePeriodBar(
            period: state.period,
            range: view.range,
            onGranularityChanged: cubit.setGranularity,
            onPrevious: cubit.previousPeriod,
            onNext: cubit.nextPeriod,
            onCurrent: cubit.currentPeriod,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        if (state.isLoading) ...[
          const EteeloKpiBandSkeleton(count: 4),
          const SizedBox(height: AppDimensions.spacingM),
          const EteeloChartSkeleton(),
        ] else if (view.isEmpty)
          EteeloEmptyResult(
            label: l10n.expenseEmptyPeriodTitle(label.demonstrative),
            description: l10n.expenseDashboardEmptyMessage(label.detail),
            medallionIcon: Icons.date_range_outlined,
            fullWidthCard: true,
            primaryAction: widen
                ? EteeloButton.primary(
                    label: l10n.expenseShowWholeMonth,
                    icon: Icons.calendar_month_outlined,
                    onPressed: cubit.showWholeMonth,
                    fullWidth: false,
                  )
                : EteeloButton.primary(
                    label: registerLabel,
                    icon: registerIcon,
                    onPressed: openRegister,
                    fullWidth: false,
                  ),
            secondaryAction: widen
                ? EteeloButton.secondary(
                    label: registerLabel,
                    icon: registerIcon,
                    onPressed: openRegister,
                    fullWidth: false,
                  )
                : null,
          )
        else ...[
          ExpenseDashboardKpiBand(
            view: view,
            previousLabel: l10n.expensePreviousPeriod(
              _granularityKey(state.period.granularity),
            ),
          ),
          ExpenseRateNote(rate: state.snapshot.usdToCdf, totals: view.total),
          const SizedBox(height: AppDimensions.spacingM),
          ExpenseEvolutionCard(
            view: view,
            granularity: state.period.granularity,
            periodDetail: label.detail,
            rate: state.snapshot.usdToCdf,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _TwoColumns(
            left: ExpenseBreakdownCard(view: view),
            right: ExpenseTopTypesCard(
              view: view,
              onOpenType: (typeId) {
                cubit.requestRegisterType(typeId);
                openRegister();
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ExpenseInsightsRow(
            view: view,
            demonstrative: label.demonstrative,
            rate: state.snapshot.usdToCdf,
            onOpenRegister: openRegister,
          ),
        ],
      ],
    );
  }

  static String _granularityKey(ExpenseGranularity granularity) =>
      switch (granularity) {
        ExpenseGranularity.day => 'day',
        ExpenseGranularity.week => 'week',
        ExpenseGranularity.month => 'month',
        ExpenseGranularity.schoolYear => 'year',
      };
}

class _TwoColumns extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _TwoColumns({required this.left, required this.right});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth <
          AppDimensions.expenseDashboardTwoColumnsMinWidth) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            const SizedBox(height: AppDimensions.spacingM),
            right,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(child: right),
        ],
      );
    },
  );
}
