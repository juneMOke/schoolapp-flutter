import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_category_card.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_dashboard_kpis.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_parity_card.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_roster_card.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_sync_insight.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_two_columns.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord prêt, de haut en bas : le chiffre, ce qui n'est pas
/// encore parvenu au serveur, la répartition, les personnes.
class HrDashboardContent extends StatelessWidget {
  final HrStaffStats stats;

  /// Fiches et pièces encore sur la tablette : ni dans les chiffres, ni dans
  /// la liste, ni dans le PDF tant que le serveur ne les a pas reçues.
  final int pending;
  final RecordSyncState Function(String id) syncOf;

  /// Porte la clé vers laquelle l'écran défile.
  final Key rosterKey;
  final ValueChanged<HrCategoryKey> onCategoryTap;
  final ValueChanged<HrStaffMemberRow> onOpen;

  const HrDashboardContent({
    super.key,
    required this.stats,
    required this.pending,
    required this.syncOf,
    required this.rosterKey,
    required this.onCategoryTap,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = context.read<HrStaffMembersCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrDashboardKpis(stats: stats),
        if (pending > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          HrSyncInsight(pending: pending),
        ],
        const SizedBox(height: AppSpacing.lg),
        BlocSelector<HrStaffMembersCubit, HrStaffMembersState, HrCategoryKey?>(
          selector: (state) => state.query.category,
          builder: (context, active) => HrTwoColumns(
            first: HrCategoryCard(
              stats: stats,
              active: active,
              onTap: onCategoryTap,
            ),
            second: HrParityCard(stats: stats),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<HrStaffMembersCubit, HrStaffMembersState>(
          builder: (context, state) => HrRosterCard(
            key: rosterKey,
            members: state,
            stats: stats,
            syncOf: syncOf,
            onTextChanged: members.setText,
            onCategoryChanged: members.setCategory,
            onSortChanged: members.setSort,
            onClearFilters: members.clearFilters,
            onOpen: onOpen,
            onPageChanged: members.pageChanged,
            onRetry: members.retry,
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
