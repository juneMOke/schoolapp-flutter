import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_list_report_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_stats_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_cubit.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/hr_personnel_state.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/context/hr_agent_intent.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/common/hr_query_location.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_dashboard_body.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/features/staff/presentation/pages/staff_agent_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Personnel ▸ Tableau de bord — combien d'agents, comment ils se
/// répartissent, et qui ils sont.
///
/// **En ligne**, comme Inscriptions, Caisse et Boutique : chiffres, liste et
/// PDF viennent du serveur, sur les mêmes critères — l'écran et le papier ne
/// divergent jamais. Le fichier local ne sert plus qu'à dire ce qui n'est pas
/// encore parti, et à ouvrir une fiche sans attendre.
class HrDashboardPage extends StatelessWidget {
  const HrDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<HrPersonnelCubit>(
        create: (_) => getIt<HrPersonnelCubit>()..load(),
      ),
      BlocProvider<HrStaffStatsCubit>(
        create: (_) => getIt<HrStaffStatsCubit>()..load(),
      ),
      BlocProvider<HrStaffMembersCubit>(
        create: (_) => getIt<HrStaffMembersCubit>()..load(),
      ),
      BlocProvider<HrStaffListReportCubit>(
        create: (_) => getIt<HrStaffListReportCubit>(),
      ),
    ],
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
    // La liste vient d'être redemandée : attendre qu'elle soit peinte.
    await WidgetsBinding.instance.endOfFrame;
    final target = _rosterKey.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(target, duration: AppMotion.layout);
  }

  void _onCategoryTap(HrCategoryKey key) {
    // Une catégorie que le serveur ne connaît pas ne se filtre pas.
    if (key == HrCategoryKey.unknown) return;
    unawaited(context.read<HrStaffMembersCubit>().toggleCategory(key));
    unawaited(_scrollToRoster());
  }

  /// Le serveur a pu recevoir quelque chose : les chiffres et la page se
  /// relisent, sans squelette.
  void _rereadServer() {
    unawaited(context.read<HrStaffStatsCubit>().load());
    unawaited(context.read<HrStaffMembersCubit>().reload());
  }

  Future<void> _reload() async {
    _rereadServer();
    await context.read<HrPersonnelCubit>().reload();
  }

  /// Ouvre la fiche — depuis le fichier local quand la tablette l'a, sans
  /// attendre —, puis relit : elle a pu changer.
  Future<void> _openAgent(HrStaffMemberRow row) async {
    final local = context.read<HrPersonnelCubit>().state;
    final view = _viewOf(local);
    final known = view.all.where((r) => r.member.id == row.id).firstOrNull;
    if (known == null) {
      await HrAgentIntent.openById(
        context,
        subMenuId: MenuConstants.hrPersonnelDashboardId,
        agentId: row.id,
      );
    } else {
      await HrAgentIntent.open(
        context,
        subMenuId: MenuConstants.hrPersonnelDashboardId,
        row: known,
        others: local.snapshot.members,
        today: local.today,
      );
    }
    if (!mounted) return;
    await context.read<HrPersonnelCubit>().refresh();
    if (mounted) _rereadServer();
  }

  /// Une fiche neuve n'a pas d'adresse : elle s'ouvre par-dessus l'écran.
  Future<void> _createAgent() async {
    final local = context.read<HrPersonnelCubit>().state;
    await StaffAgentPage.open(
      context,
      others: local.snapshot.members,
      today: local.today,
    );
    if (!mounted) return;
    await context.read<HrPersonnelCubit>().refresh();
    if (mounted) _rereadServer();
  }

  /// Pour retrouver la ligne locale d'un agent : ses pièces n'y comptent pas.
  StaffFileView _viewOf(HrPersonnelState local) => StaffFileView.build(
    local.snapshot,
    query: StaffFileQuery.none,
    today: local.today,
    documentsVisible: false,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // F5 / Ctrl+R : relire le serveur et redescendre le fichier, sans
    // recharger la page web.
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(_reload()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        // Dans la coquille, sa barre d'en-tête nomme déjà l'écran.
        appBar: ShellChrome.wraps(context)
            ? null
            : ModuleTopBar(
                eyebrow: l10n.hrPersonnelEyebrow,
                title: l10n.subMenuDashboard,
              ),
        // Un envoi achevé change ce que le serveur sait : relire.
        child: BlocListener<HrPersonnelCubit, HrPersonnelState>(
          listenWhen: (previous, current) =>
              previous.status == HrPersonnelStatus.ready &&
              current.status == HrPersonnelStatus.ready &&
              previous.snapshot != current.snapshot,
          listener: (_, _) => _rereadServer(),
          // Catégorie et ordre de « Qui sont-ils » dans l'adresse ; pas de
          // bascule cartes/liste ici.
          child:
              BlocSelector<
                HrStaffMembersCubit,
                HrStaffMembersState,
                HrRosterQuery
              >(
                selector: (state) => state.query,
                builder: (context, query) => HrQueryLocation(
                  query: query,
                  onLocation: (filters) => unawaited(
                    context.read<HrStaffMembersCubit>().applyLocation(filters),
                  ),
                  child: BlocBuilder<HrStaffStatsCubit, HrStaffStatsState>(
                    builder: (context, stats) =>
                        BlocBuilder<HrPersonnelCubit, HrPersonnelState>(
                          buildWhen: (previous, current) =>
                              previous.snapshot != current.snapshot,
                          builder: (context, local) => HrDashboardBody(
                            stats: stats,
                            local: local,
                            rosterKey: _rosterKey,
                            onScrollToRoster: () =>
                                unawaited(_scrollToRoster()),
                            onCategoryTap: _onCategoryTap,
                            onOpen: (row) => unawaited(_openAgent(row)),
                            onCreate: () => unawaited(_createAgent()),
                          ),
                        ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
