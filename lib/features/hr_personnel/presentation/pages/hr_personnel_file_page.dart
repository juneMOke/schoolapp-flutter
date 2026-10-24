import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_state.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_query_location.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/file/hr_file_filters_card.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/grid/staff_agent_grid.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/list/staff_agent_table.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_empty_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_file_skeleton.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Personnel ▸ Fichier du personnel — l'écran de travail : trouver un
/// agent et ouvrir sa fiche. **Aucune statistique** : elles vivent au tableau
/// de bord.
///
/// La page agent est celle du fichier existant, poussée par-dessus : quand
/// elle se referme, recherche, catégorie et affichage sont restés en place.
class HrPersonnelFilePage extends StatelessWidget {
  const HrPersonnelFilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<HrPersonnelCubit>(
    create: (_) => getIt<HrPersonnelCubit>()..load(),
    child: const HrPersonnelFileScreen(),
  );
}

class HrPersonnelFileScreen extends StatelessWidget {
  const HrPersonnelFileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // F5 / Ctrl+R : redescendre le fichier, sans recharger la page web.
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(context.read<HrPersonnelCubit>().reload()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        appBar: ShellChrome.wraps(context)
            ? null
            : ModuleTopBar(
                eyebrow: l10n.hrPersonnelEyebrow,
                title: l10n.subMenuHrPersonnelFile,
              ),
        child: BlocBuilder<HrPersonnelCubit, HrPersonnelState>(
          buildWhen: (previous, current) => previous != current,
          builder: (context, state) => HrQueryLocation(
            query: state.query,
            viewMode: state.viewMode,
            onLocation: context.read<HrPersonnelCubit>().applyLocation,
            child: _body(context, state),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, HrPersonnelState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPersonnelCubit>();

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

    // Une base illisible n'accepte pas non plus d'écriture.
    final VoidCallback? create = state.status == HrPersonnelStatus.failure
        ? null
        : () => unawaited(open());

    final header = HrPersonnelHeader(
      subtitle: l10n.hrFileSubtitle,
      actions: [
        PermissionGate.access(
          kStaffWriteAccess,
          // Ctrl+N : la même fiche neuve que le bouton, sous le même droit.
          child: PageActionShortcut(
            action: PageAction.create,
            onInvoke: create,
            child: EteeloButton.primary(
              label: l10n.staffActionNewAgent,
              icon: Icons.person_add_alt,
              onPressed: create,
              fullWidth: false,
            ),
          ),
        ),
      ],
    );
    final filters = HrFileFiltersCard(
      query: state.query,
      viewMode: state.viewMode,
      onTextChanged: cubit.setText,
      onCategoryChanged: cubit.setCategory,
      onSortChanged: cubit.setSort,
      onViewModeChanged: cubit.setViewMode,
    );

    final List<Widget> results;
    switch (state.status) {
      case HrPersonnelStatus.loading:
        results = [StaffFileSkeleton(viewMode: state.viewMode)];
      case HrPersonnelStatus.failure:
        results = [
          StaffResultsErrorState(failure: state.failure, onRetry: cubit.load),
        ];
      case HrPersonnelStatus.ready:
        results = _results(context, state, open);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.status == HrPersonnelStatus.ready &&
            !state.snapshot.hasEverSynced)
          EteeloNotice.warning(l10n.staffFileNotYetSynced),
        header,
        const SizedBox(height: AppSpacing.lg),
        filters,
        const SizedBox(height: AppSpacing.lg),
        ...results,
      ],
    );
  }

  List<Widget> _results(
    BuildContext context,
    HrPersonnelState state,
    Future<void> Function({StaffFileRow? row, String prefill}) open,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPersonnelCubit>();
    final view = StaffFileView.build(
      state.snapshot,
      query: StaffFileQuery.none,
      today: state.today,
      documentsVisible: PermissionGate.allows(context, const [
        Perm.hrDocumentRead,
      ]),
    );
    if (view.isFileEmpty) {
      return [
        StaffEmptyState(
          filtered: false,
          onResetFilters: cubit.clearFilters,
          onCreate: () => unawaited(open()),
        ),
      ];
    }
    final rows = state.query.apply(view.all);
    final total = view.all.length;
    return [
      if (rows.isEmpty)
        StaffEmptyState(
          filtered: true,
          onResetFilters: cubit.clearFilters,
          onCreate: state.query.hasText
              ? () => unawaited(open(prefill: state.query.text))
              : null,
        )
      else if (state.viewMode == CollectionViewMode.grid)
        StaffAgentGrid(
          rows: rows,
          onOpen: (row) => unawaited(open(row: row)),
        )
      else
        StaffAgentTable(
          rows: rows,
          showDossier: view.documentsVisible,
          onOpen: (row) => unawaited(open(row: row)),
          onAgentSort: cubit.toggleNameOrder,
          agentDescending: state.query.sort == HrRosterSort.nameDescending,
        ),
      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          state.query.isFiltering
              ? l10n.hrFileFooterFiltered(
                  l10n.hrAgentsCount(rows.length),
                  total,
                )
              : l10n.hrFileFooterAll(total),
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
        ),
      ),
    ];
  }
}
