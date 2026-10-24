import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_stats_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_state.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_dashboard_content.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_sync_insight.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/states/hr_dashboard_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau de bord sous son en-tête : les chiffres du serveur, ou leur
/// attente, leur échec, le fichier vide.
///
/// Le fichier local [local] n'y dit que deux choses : ce qui n'est pas encore
/// parti, et où en est chaque fiche sur cette tablette.
class HrDashboardBody extends StatelessWidget {
  final HrStaffStatsState stats;
  final HrPersonnelState local;
  final Key rosterKey;
  final VoidCallback onScrollToRoster;
  final ValueChanged<HrCategoryKey> onCategoryTap;
  final ValueChanged<HrStaffMemberRow> onOpen;
  final VoidCallback onCreate;

  const HrDashboardBody({
    super.key,
    required this.stats,
    required this.local,
    required this.rosterKey,
    required this.onScrollToRoster,
    required this.onCategoryTap,
    required this.onOpen,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final figures = stats.stats;
    final empty = figures != null && figures.headcount == 0;
    // Tant que le fichier local n'est pas lu (ou s'il est illisible), on ne
    // sait ni ce qui attend ni où en est chaque fiche : rien ne le prétend.
    final localKnown = local.status == HrPersonnelStatus.ready;
    // Les pièces en attente ne se comptent que pour qui les voit.
    final pending = localKnown
        ? StaffFileView.build(
            local.snapshot,
            query: StaffFileQuery.none,
            today: local.today,
            documentsVisible: PermissionGate.allows(context, const [
              Perm.hrDocumentRead,
            ]),
          ).pending
        : 0;
    final syncById = {
      for (final member in local.snapshot.members) member.id: member.syncState,
    };
    RecordSyncState? syncOf(String id) =>
        localKnown ? syncById[id] ?? RecordSyncState.synced : null;

    final header = HrPersonnelHeader(
      subtitle: _subtitle(context, l10n, figures?.headcount),
      actions: [
        if (figures != null && !empty)
          EteeloButton.secondary(
            label: l10n.hrDashboardActionList,
            icon: Icons.groups_outlined,
            onPressed: onScrollToRoster,
            fullWidth: false,
          ),
        EteeloButton.primary(
          label: l10n.hrDashboardActionOpenFile,
          icon: Icons.work_outline,
          // Dans la coquille, comme un choix du menu : une route seule
          // afficherait la page nue, sans barre ni retour.
          onPressed: () => context.read<NavigationBloc>().add(
            SubMenuItemSelected(
              menuId: MenuConstants.hrPersonnelMenuId,
              subMenuId: MenuConstants.hrPersonnelFileId,
              title: l10n.subMenuHrPersonnelFile,
            ),
          ),
          fullWidth: false,
        ),
      ],
    );

    final Widget content;
    switch (stats.status) {
      case HrStaffStatsStatus.loading:
        content = const HrDashboardSkeleton();
      case HrStaffStatsStatus.failure:
        content = HrDashboardResultsErrorState(
          failure: stats.failure,
          onRetry: () {
            unawaited(context.read<HrStaffStatsCubit>().load());
            unawaited(context.read<HrStaffMembersCubit>().retry());
          },
        );
      case HrStaffStatsStatus.ready when empty:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Des agents saisis ici, pas encore reçus : le fichier n'est
            // vide que pour le serveur — et proposer d'en ajouter un
            // inviterait au doublon.
            if (pending > 0) ...[
              HrSyncInsight(pending: pending),
              const SizedBox(height: AppSpacing.lg),
              EteeloEmptyResult(
                label: l10n.hrDashboardPendingOnlyTitle,
                description: l10n.hrDashboardPendingOnlyMessage,
                medallionIcon: Icons.cloud_upload_outlined,
                fullWidthCard: true,
              ),
            ] else
              EteeloEmptyResult(
                label: l10n.hrDashboardEmptyTitle,
                description: l10n.hrDashboardEmptyMessage,
                medallionIcon: Icons.groups_outlined,
                fullWidthCard: true,
                primaryAction: PermissionGate.access(
                  kStaffWriteAccess,
                  child: EteeloButton.primary(
                    label: l10n.hrDashboardEmptyAction,
                    icon: Icons.person_add_alt,
                    onPressed: onCreate,
                    fullWidth: false,
                  ),
                ),
              ),
          ],
        );
      case HrStaffStatsStatus.ready:
        content = HrDashboardContent(
          stats: figures!,
          pending: pending,
          syncOf: syncOf,
          rosterKey: rosterKey,
          onCategoryTap: onCategoryTap,
          onOpen: onOpen,
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }

  /// [count] `null` : les chiffres ne sont pas encore arrivés — pas de « 0
  /// agent » qui se lirait comme un fichier vide.
  String _subtitle(BuildContext context, AppLocalizations l10n, int? count) {
    final year = context.select<AcademicYearContextBloc, String?>(
      (bloc) => bloc.state.context?.academicYear.name,
    );
    if (count == null) return l10n.hrDashboardSubtitleBare;
    final agents = l10n.hrAgentsCount(count);
    return year == null
        ? l10n.hrDashboardSubtitleNoYear(agents)
        : l10n.hrDashboardSubtitle(agents, year);
  }
}
