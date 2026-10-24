import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_state.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_query_location.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_dashboard_content.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Personnel ▸ Tableau de bord — combien d'agents, comment ils se
/// répartissent, et qui ils sont.
///
/// Le tableau de bord **lit** : tout est calculé sur la tablette depuis le
/// fichier local, saisies hors ligne comprises ; aucun chiffre n'est demandé
/// au serveur.
class HrDashboardPage extends StatelessWidget {
  const HrDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<HrPersonnelCubit>(
    create: (_) => getIt<HrPersonnelCubit>()..load(),
    child: const HrDashboardScreen(),
  );
}

class HrDashboardScreen extends StatefulWidget {
  const HrDashboardScreen({super.key});

  @override
  State<HrDashboardScreen> createState() => _HrDashboardScreenState();
}

class _HrDashboardScreenState extends State<HrDashboardScreen> {
  final GlobalKey _rosterKey = GlobalKey();

  /// Descend jusqu'à « Qui sont-ils » — après un tap sur une catégorie, ou
  /// sur « Liste du personnel ».
  Future<void> _scrollToRoster() async {
    // La liste vient d'être refiltrée : attendre qu'elle soit peinte.
    await WidgetsBinding.instance.endOfFrame;
    final target = _rosterKey.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(target, duration: AppMotion.layout);
  }

  void _onCategoryTap(HrCategoryKey key) {
    context.read<HrPersonnelCubit>().toggleCategory(key);
    unawaited(_scrollToRoster());
  }

  /// Ouvre la fiche (ou une fiche neuve), puis relit : elle a pu changer.
  Future<void> _openAgent(HrPersonnelState state, {StaffFileRow? row}) async {
    final cubit = context.read<HrPersonnelCubit>();
    await StaffAgentPage.open(
      context,
      member: row?.member,
      kind: row?.kind,
      others: state.snapshot.members,
      today: state.today,
    );
    if (!mounted) return;
    await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // F5 / Ctrl+R : redescendre le fichier, sans recharger la page web.
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(context.read<HrPersonnelCubit>().reload()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        // Dans la coquille, sa barre d'en-tête nomme déjà l'écran.
        appBar: ShellChrome.wraps(context)
            ? null
            : ModuleTopBar(
                eyebrow: l10n.hrPersonnelEyebrow,
                title: l10n.subMenuDashboard,
              ),
        child: BlocBuilder<HrPersonnelCubit, HrPersonnelState>(
          buildWhen: (previous, current) => previous != current,
          // Catégorie et ordre de « Qui sont-ils » dans l'adresse ; pas de
          // bascule cartes/liste ici.
          builder: (context, state) => HrQueryLocation(
            query: state.query,
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
    final ready = state.status == HrPersonnelStatus.ready;
    final view = StaffFileView.build(
      state.snapshot,
      query: StaffFileQuery.none,
      today: state.today,
      documentsVisible: PermissionGate.allows(context, const [
        Perm.hrDocumentRead,
      ]),
    );
    final stats = HrStaffStats.of(view, today: state.today);
    final empty = ready && view.isFileEmpty;

    final header = HrPersonnelHeader(
      subtitle: _subtitle(context, l10n, stats.headcount),
      actions: [
        if (ready && !empty)
          EteeloButton.secondary(
            label: l10n.hrDashboardActionList,
            icon: Icons.groups_outlined,
            onPressed: () => unawaited(_scrollToRoster()),
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
    switch (state.status) {
      case HrPersonnelStatus.loading:
        content = const HrDashboardSkeleton();
      case HrPersonnelStatus.failure:
        content = StaffResultsErrorState(
          failure: state.failure,
          onRetry: cubit.load,
        );
      case HrPersonnelStatus.ready when empty:
        content = EteeloEmptyResult(
          label: l10n.hrDashboardEmptyTitle,
          description: l10n.hrDashboardEmptyMessage,
          medallionIcon: Icons.groups_outlined,
          fullWidthCard: true,
          primaryAction: PermissionGate.access(
            kStaffWriteAccess,
            child: EteeloButton.primary(
              label: l10n.hrDashboardEmptyAction,
              icon: Icons.person_add_alt,
              onPressed: () => unawaited(_openAgent(state)),
              fullWidth: false,
            ),
          ),
        );
      case HrPersonnelStatus.ready:
        content = HrDashboardContent(
          state: state,
          view: view,
          stats: stats,
          rosterKey: _rosterKey,
          onCategoryTap: _onCategoryTap,
          onOpen: (row) => unawaited(_openAgent(state, row: row)),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ready && !state.snapshot.hasEverSynced)
          EteeloNotice.warning(l10n.staffFileNotYetSynced),
        header,
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }

  String _subtitle(BuildContext context, AppLocalizations l10n, int count) {
    final year = context.select<AcademicYearContextBloc, String?>(
      (bloc) => bloc.state.context?.academicYear.name,
    );
    final agents = l10n.hrAgentsCount(count);
    return year == null
        ? l10n.hrDashboardSubtitleNoYear(agents)
        : l10n.hrDashboardSubtitle(agents, year);
  }
}
