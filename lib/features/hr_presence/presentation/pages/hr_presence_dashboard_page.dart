import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_attendance_report_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_cubit.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_dashboard_body.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/hr_dashboard_location.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Présences ▸ Tableau de bord — qui vient, qui manque, sur la période.
///
/// **En ligne** (D1), comme les autres tableaux de bord : indicateurs,
/// graphique, liste et PDF viennent du serveur, sur les mêmes `from` / `to`.
/// La tablette n'ajoute que ce qu'elle n'a pas encore envoyé.
class HrPresenceDashboardPage extends StatelessWidget {
  const HrPresenceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<HrPresenceDashboardCubit>(
        create: (context) =>
            getIt<HrPresenceDashboardCubit>()
              ..start(yearStart: _yearStart(context)),
      ),
      BlocProvider<HrAttendanceReportCubit>(
        create: (_) => getIt<HrAttendanceReportCubit>(),
      ),
    ],
    child: const HrPresenceDashboardScreen(),
  );

  /// L'ouverture de l'année, si le contexte la connaît déjà.
  static DateTime? _yearStart(BuildContext context) {
    try {
      return context
          .read<AcademicYearContextBloc>()
          .state
          .context
          ?.academicYear
          .startDate;
    } on Object {
      return null;
    }
  }
}

class HrPresenceDashboardScreen extends StatelessWidget {
  /// `null` : les lignes d'agent ne s'ouvrent pas.
  final ValueChanged<HrAttendanceStaffRow>? onOpenAgent;

  const HrPresenceDashboardScreen({super.key, this.onOpenAgent});

  /// Dans la coquille, comme un choix du menu : une route seule afficherait
  /// la page nue, sans barre ni retour.
  static void openRegister(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: MenuConstants.hrPresenceMenuId,
        subMenuId: MenuConstants.hrPresenceRegisterId,
        title: l10n.subMenuHrPresenceRegister,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<HrPresenceDashboardCubit>();
    // F5 / Ctrl+R : relire le serveur, sans recharger la page web.
    return PageActionShortcut(
      action: PageAction.refresh,
      onInvoke: () => unawaited(cubit.reload()),
      child: AppPageBackground(
        width: PageContentWidth.wide,
        // Dans la coquille, sa barre d'en-tête nomme déjà l'écran.
        appBar: ShellChrome.wraps(context)
            ? null
            : ModuleTopBar(
                eyebrow: l10n.hrPresenceEyebrow,
                title: l10n.subMenuDashboard,
              ),
        child: BlocBuilder<HrPresenceDashboardCubit, HrPresenceDashboardState>(
          builder: (context, state) => HrDashboardLocation(
            state: state,
            cubit: cubit,
            child: HrPresenceDashboardBody(
              state: state,
              onOpenRegister: () => openRegister(context),
              onOpen: onOpenAgent,
            ),
          ),
        ),
      ),
    );
  }
}
