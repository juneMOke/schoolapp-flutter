import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_state.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/export/hr_staff_list_export.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_category_card.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_dashboard_kpis.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_parity_card.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_roster_card.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_sync_insight.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_two_columns.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord prêt, de haut en bas : le chiffre, la répartition, les
/// personnes, puis le renvoi vers la présence et la paie.
class HrDashboardContent extends StatelessWidget {
  final HrPersonnelState state;
  final StaffFileView view;
  final HrStaffStats stats;

  /// Porte la clé vers laquelle l'écran défile.
  final Key rosterKey;
  final ValueChanged<HrCategoryKey> onCategoryTap;
  final ValueChanged<StaffFileRow> onOpen;

  const HrDashboardContent({
    super.key,
    required this.state,
    required this.view,
    required this.stats,
    required this.rosterKey,
    required this.onCategoryTap,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPersonnelCubit>();
    final rows = state.query.apply(view.all);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDashboardKpis(stats: stats),
        if (stats.pending > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          HrSyncInsight(pending: stats.pending),
        ],
        const SizedBox(height: AppSpacing.lg),
        HrTwoColumns(
          first: HrCategoryCard(
            stats: stats,
            active: state.query.category,
            onTap: onCategoryTap,
          ),
          second: HrParityCard(stats: stats),
        ),
        const SizedBox(height: AppSpacing.lg),
        HrRosterCard(
          key: rosterKey,
          rows: rows,
          query: state.query,
          stats: stats,
          today: state.today,
          onTextChanged: cubit.setText,
          onCategoryChanged: cubit.setCategory,
          onSortChanged: cubit.setSort,
          onClearFilters: cubit.clearFilters,
          onOpen: onOpen,
          onExportPdf: () => unawaited(
            HrStaffListExport.run(
              context,
              rows: rows,
              query: state.query,
              today: state.today,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.hrDashboardFootnote,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textMutedAa),
        ),
      ],
    );
  }
}
