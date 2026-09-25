import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_queue_cubit.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_queue_state.dart';
import 'package:school_app_flutter/features/expense/presentation/bloc/expense_register_state.dart';
import 'package:school_app_flutter/features/expense/presentation/pages/expense_queue_actions.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/services/expense_money.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_queue_approved_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_queue_batch_bar.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_queue_kpi_band.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/queue/expense_queue_list.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/states/expense_queue_empty_state.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/states/expense_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Dépenses ▸ Validations — la file des demandes en attente.
///
/// Elle lit le même registre local que les deux autres écrans, **sans leur
/// période** : une demande déposée le mois dernier attend toujours, et la
/// masquer serait cacher exactement le retard que cet écran existe pour
/// montrer.
class ExpenseQueuePage extends StatelessWidget {
  const ExpenseQueuePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ExpenseQueueCubit>(
    create: (_) => getIt<ExpenseQueueCubit>()..load(),
    child: const ExpenseQueueScreen(),
  );
}

class ExpenseQueueScreen extends StatelessWidget {
  const ExpenseQueueScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    child: BlocBuilder<ExpenseQueueCubit, ExpenseQueueState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.view != curr.view ||
          prev.sort != curr.sort ||
          prev.selection != curr.selection ||
          prev.snapshot != curr.snapshot ||
          prev.failure != curr.failure,
      builder: _body,
    ),
  );

  Widget _body(BuildContext context, ExpenseQueueState state) {
    final cubit = context.read<ExpenseQueueCubit>();
    final failure = state.failure;
    if (state.status == ExpenseLoadStatus.failure && failure != null) {
      return ExpenseResultsErrorState(failure: failure, onRetry: cubit.load);
    }
    if (state.isLoading) {
      return const EteeloListSkeleton(rowCount: 6, showAvatar: false);
    }
    final actions = ExpenseQueueActions(context);
    final view = state.view;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le repli dit à qui ne décide pas ce qu'il peut encore faire. Le
        // taire laisserait croire à une file en lecture seule, alors que le
        // demandeur y garde la main sur ses propres lignes.
        PermissionGate.access(
          kExpenseDecideAccess,
          fallback: const _ReadOnlyNote(),
          child: const SizedBox.shrink(),
        ),
        ExpenseQueueKpiBand(view: view),
        const SizedBox(height: AppDimensions.spacingM),
        if (view.isEmpty)
          ExpenseQueueEmptyState(
            approvedToPay: view.approvedTotal.count,
            onOpenRegister: () => context.go(AppRoutesNames.expenseRegister),
          )
        else
          ExpenseQueueList(
            view: view,
            typesById: state.snapshot.typesById,
            reader: state.snapshot.usdReader,
            today: state.today,
            accountId: _agentId(context),
            sort: state.sort,
            selection: state.selection,
            allSelected: state.allSelected,
            onSortChanged: cubit.setSort,
            onToggleSelection: cubit.toggleSelection,
            onToggleAll: cubit.toggleAll,
            onOpen: actions.open,
            onRefuse: (expense) => actions.open(expense, refusing: true),
            onGesture: actions.applyGesture,
            batchBar: state.hasSelection
                ? ExpenseQueueBatchBar(
                    count: state.selection.length,
                    totals: ExpenseTotals.of(
                      cubit.selectedExpenses,
                      state.snapshot.usdReader,
                    ),
                    onClear: cubit.clearSelection,
                    onApprove: () => actions.applyBatch(ExpenseGesture.approve),
                    onRefuse: (reason) =>
                        actions.applyBatch(ExpenseGesture.refuse, note: reason),
                  )
                : null,
          ),
        // Sous la file, et toujours : la file vide ne veut pas dire que
        // l'école ne doit plus rien.
        ExpenseQueueApprovedCard(
          view: view,
          onGesture: actions.applyGesture,
          onOpen: actions.open,
          onOpenRegister: () => context.go(AppRoutesNames.expenseRegister),
        ),
      ],
    );
  }

  static String? _agentId(BuildContext context) {
    final id = PermissionGate.maybeBlocOf(context)?.state.user?.id;
    return id == null || id.isEmpty ? null : id;
  }
}

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
    padding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingS + AppDimensions.spacingXS,
      vertical: AppDimensions.expenseNotePaddingV,
    ),
    decoration: BoxDecoration(
      color: AppColors.feeStatusPartialSoft,
      border: Border.all(color: AppColors.feeStatusPartialBorder),
      borderRadius: BorderRadius.circular(AppDimensions.expenseIconBoxRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline,
          size: AppDimensions.detailMiniIconSize,
          color: AppColors.feeStatusPartialInk,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.expenseQueueReadOnlyNote,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
