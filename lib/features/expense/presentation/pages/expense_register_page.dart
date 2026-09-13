import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_period_labels.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_register_actions.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_section_note.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_register_filters_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_register_kpi_band.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/register/expense_register_list.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/states/expense_empty_state.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/states/expense_results_error_state.dart';

/// Dépenses ▸ Frais de fonctionnement — le registre. C'est ici, et nulle part
/// ailleurs, qu'une dépense est créée, modifiée, dupliquée, marquée payée ou
/// retirée.
class ExpenseRegisterPage extends StatelessWidget {
  const ExpenseRegisterPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ExpenseRegisterCubit>(
    create: (_) => getIt<ExpenseRegisterCubit>()..load(),
    child: const ExpenseRegisterView(),
  );
}

class ExpenseRegisterView extends StatelessWidget {
  const ExpenseRegisterView({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    child: BlocBuilder<ExpenseRegisterCubit, ExpenseRegisterState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.view != curr.view ||
          prev.period != curr.period ||
          prev.query != curr.query ||
          prev.snapshot != curr.snapshot ||
          prev.failure != curr.failure,
      builder: _body,
    ),
  );

  Widget _body(BuildContext context, ExpenseRegisterState state) {
    final cubit = context.read<ExpenseRegisterCubit>();
    final failure = state.failure;
    if (state.status == ExpenseLoadStatus.failure && failure != null) {
      return ExpenseResultsErrorState(failure: failure, onRetry: cubit.load);
    }
    final actions = ExpenseRegisterActions(context);
    final view = state.view;
    final label = ExpensePeriodLabel.of(context, state.period, view.range);
    final types = [
      for (final type in state.snapshot.types)
        if (type.active || (view.typeCounts[type.id] ?? 0) > 0) type,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpenseRegisterFiltersCard(
          period: state.period,
          range: view.range,
          types: types,
          query: state.query,
          typeCounts: view.typeCounts,
          onGranularityChanged: cubit.setGranularity,
          onPrevious: cubit.previousPeriod,
          onNext: cubit.nextPeriod,
          onCurrent: cubit.currentPeriod,
          onToggleType: cubit.toggleType,
          onClearTypes: cubit.clearTypes,
          onStatusChanged: cubit.setStatusFilter,
          onTextChanged: cubit.setText,
          onCreate: actions.create,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        if (state.isLoading)
          const EteeloKpiBandSkeleton(count: 4)
        else ...[
          ExpenseRegisterKpiBand(view: view, periodDetail: label.detail),
          ExpenseRateNote(rate: state.snapshot.usdToCdf, totals: view.total),
        ],
        const SizedBox(height: AppDimensions.spacingM),
        if (state.isLoading)
          const EteeloListSkeleton(rowCount: 6, showAvatar: false)
        else if (view.isEmpty)
          ExpenseEmptyState(
            // Un filtre ne « vide » qu'une période qui a des dépenses ; sur
            // une période vide, c'est la période qu'il faut changer.
            filtered: state.query.isActive && view.typeCounts.isNotEmpty,
            demonstrative: label.demonstrative,
            detail: label.detail,
            onCreate: actions.create,
            onResetFilters: cubit.resetFilters,
            onShowWholeMonth: state.period.canWidenToMonth
                ? cubit.showWholeMonth
                : null,
          )
        else
          ExpenseRegisterList(
            view: view,
            typesById: state.snapshot.typesById,
            reader: state.snapshot.usdReader,
            onOpen: actions.open,
            onToggle: actions.toggle,
            onDuplicate: actions.duplicate,
            onShowMore: cubit.showMore,
          ),
      ],
    );
  }
}
