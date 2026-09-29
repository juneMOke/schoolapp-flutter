import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_state.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_filters_card.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/grid/staff_agent_grid.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/list/staff_agent_table.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_empty_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_file_skeleton.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/stats/staff_stats_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ressources humaines ▸ Fichier du personnel — tous les agents de l'école.
///
/// Lecture 100 % locale : filtres, recherche et bascule cartes/liste se
/// recalculent en mémoire, sans jamais repasser par la base ni par le réseau.
class StaffFilePage extends StatelessWidget {
  const StaffFilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<StaffFileCubit>(
    create: (_) => getIt<StaffFileCubit>()..load(),
    child: const StaffFileScreen(),
  );
}

class StaffFileScreen extends StatelessWidget {
  const StaffFileScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
    child: BlocBuilder<StaffFileCubit, StaffFileState>(
      buildWhen: (previous, current) => previous != current,
      builder: _body,
    ),
  );

  Widget _body(BuildContext context, StaffFileState state) {
    final cubit = context.read<StaffFileCubit>();
    switch (state.status) {
      case StaffFileStatus.failure:
        return StaffResultsErrorState(
          failure: state.failure,
          onRetry: cubit.load,
        );
      case StaffFileStatus.neverSynced:
        return StaffResultsErrorState(neverSynced: true, onRetry: cubit.load);
      case StaffFileStatus.loading:
        return StaffFileSkeleton(viewMode: state.viewMode);
      case StaffFileStatus.ready:
        break;
    }

    final view = StaffFileView.build(
      state.snapshot,
      query: state.query,
      today: state.today,
      documentsVisible: PermissionGate.allows(context, const [
        Perm.hrDocumentRead,
      ]),
    );
    Future<void> open({StaffFileRow? row, String prefill = ''}) async {
      await StaffAgentPage.open(
        context,
        member: row?.member,
        kind: row?.kind,
        others: state.snapshot.members,
        today: state.today,
        prefill: prefill,
      );
      if (context.mounted) await cubit.refresh();
    }

    if (view.isFileEmpty) {
      return StaffEmptyState(
        filtered: false,
        onResetFilters: cubit.resetFilters,
        onCreate: () => unawaited(open()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: PermissionGate.access(
            kStaffWriteAccess,
            child: EteeloButton.primary(
              label: AppLocalizations.of(context)!.staffActionNewAgent,
              icon: Icons.person_add_alt,
              onPressed: () => unawaited(open()),
              fullWidth: false,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StaffStatsBand(view: view),
        const SizedBox(height: AppSpacing.lg),
        StaffFiltersCard(
          query: state.query,
          view: view,
          viewMode: state.viewMode,
          onTextChanged: cubit.setText,
          onCategoryChanged: cubit.setCategory,
          onContractToggled: cubit.toggleContract,
          onIncompleteToggled: cubit.toggleIncomplete,
          onViewModeChanged: cubit.setViewMode,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (view.isFilteredEmpty)
          StaffEmptyState(
            filtered: true,
            onResetFilters: cubit.resetFilters,
            onCreate: state.query.text.trim().isEmpty
                ? null
                : () => unawaited(open(prefill: state.query.text)),
          )
        else if (state.viewMode == StaffViewMode.grid)
          StaffAgentGrid(
            rows: view.rows,
            onOpen: (row) => unawaited(open(row: row)),
          )
        else
          StaffAgentTable(
            rows: view.rows,
            showDossier: view.documentsVisible,
            onOpen: (row) => unawaited(open(row: row)),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppLocalizations.of(context)!.staffFooterCount(view.all.length),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
        ),
      ],
    );
  }
}
