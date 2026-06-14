import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_overview_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_context_bar.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_dashboard_header.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_empty_view.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_success_view.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Tableau de bord des présences (Disciplines ▸ Tableau de bord).
///
/// Lecture seule. En-tête (titre + période) et barre de contexte restent
/// visibles dans tous les états ; seule la grille analytique est remplacée par
/// le squelette / l'état vide / l'erreur.
class AttendanceOverviewDashboardPage extends StatefulWidget {
  const AttendanceOverviewDashboardPage({super.key});

  @override
  State<AttendanceOverviewDashboardPage> createState() =>
      _AttendanceOverviewDashboardPageState();
}

class _AttendanceOverviewDashboardPageState
    extends State<AttendanceOverviewDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<AttendanceOverviewBloc>().add(
      const AttendanceOverviewRequested(),
    );
  }

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
  }

  void _goToAttendance() {
    final l10n = AppLocalizations.of(context)!;
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: MenuConstants.disciplinesMenuId,
        subMenuId: MenuConstants.presencesId,
        title: l10n.subMenuAttendance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      scrollable: true,
      child: BlocBuilder<AttendanceOverviewBloc, AttendanceOverviewState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.overview != curr.overview ||
            prev.selectedPeriod != curr.selectedPeriod ||
            prev.errorType != curr.errorType,
        builder: (context, state) {
          final overview = state.overview;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AttendanceOverviewDashboardHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              if (overview != null) ...[
                AttendanceOverviewContextBar(context: overview.context),
                const SizedBox(height: AppDimensions.spacingL),
              ],
              // AnimatedSize lisse le changement de hauteur entre états
              // (squelette plein → vide/erreur compacts) pendant le fondu.
              AnimatedSize(
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.standard,
                  switchInCurve: AppMotion.outCurve,
                  switchOutCurve: AppMotion.inCurve,
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      '${state.status.name}-${state.errorType.name}',
                    ),
                    child: _buildBody(context, state, l10n),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AttendanceOverviewState state,
    AppLocalizations l10n,
  ) {
    return switch (state.status) {
      AttendanceOverviewStatus.loading =>
        const AttendanceOverviewDashboardSkeleton(),
      AttendanceOverviewStatus.success =>
        (state.overview?.kpis.recordedDays ?? 0) == 0
            ? AttendanceOverviewEmptyView(onTakeAttendance: _goToAttendance)
            : AttendanceOverviewSuccessView(overview: state.overview!),
      AttendanceOverviewStatus.failure => AttendanceResultsErrorState(
        type: state.errorType,
        onRetry: () => context.read<AttendanceOverviewBloc>().add(
          const AttendanceOverviewRefreshRequested(),
        ),
        onReconnect: () =>
            context.read<AuthBloc>().add(const AuthLogoutRequested()),
        onContactAdmin: _contactAdmin,
      ),
      AttendanceOverviewStatus.initial => const SizedBox.shrink(),
    };
  }
}
