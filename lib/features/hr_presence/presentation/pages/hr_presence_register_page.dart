import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/layout/shell_chrome.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/hr_personnel_header.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_tab.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/staff_attendance_notices.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// RH · Présences ▸ Registre du jour — le registre du Pointage, seul, sans les
/// onglets de l'ancien écran.
///
/// Le même registre que Ressources humaines ▸ Pointage, laissé en place : même
/// lecture locale, mêmes envois, même verrou du jour. C'est le seul écran du
/// module qui fonctionne hors ligne (D1).
class HrPresenceRegisterPage extends StatelessWidget {
  const HrPresenceRegisterPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<StaffAttendanceCubit>(
    create: (_) => getIt<StaffAttendanceCubit>()..load(),
    child: const HrPresenceRegisterScreen(),
  );
}

class HrPresenceRegisterScreen extends StatelessWidget {
  const HrPresenceRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageBackground(
      width: PageContentWidth.wide,
      // Dans la coquille, sa barre d'en-tête nomme déjà l'écran.
      appBar: ShellChrome.wraps(context)
          ? null
          : ModuleTopBar(
              eyebrow: l10n.hrPresenceEyebrow,
              title: l10n.subMenuHrPresenceRegister,
            ),
      child: BlocConsumer<StaffAttendanceCubit, StaffAttendanceState>(
        listenWhen: (previous, current) =>
            current.notice != null && previous.notice != current.notice,
        listener: (context, state) =>
            showStaffAttendanceNotice(context, state.notice!),
        buildWhen: (previous, current) =>
            previous.copyWith(notice: current.notice) != current,
        builder: _body,
      ),
    );
  }

  Widget _body(BuildContext context, StaffAttendanceState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<StaffAttendanceCubit>();
    final header = HrPersonnelHeader(subtitle: l10n.hrPresenceRegisterSubtitle);
    final Widget content = switch (state.load) {
      StaffAttendanceLoad.failure => StaffResultsErrorState(
        failure: state.failure,
        onRetry: cubit.load,
      ),
      StaffAttendanceLoad.loading => const EteeloListSkeleton(rowCount: 8),
      StaffAttendanceLoad.ready => StaffRegisterTab(state: state),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        if (state.load == StaffAttendanceLoad.ready &&
            !state.snapshot.hasEverSynced) ...[
          EteeloNotice.warning(l10n.staffFileNotYetSynced),
          const SizedBox(height: AppSpacing.lg),
        ],
        content,
      ],
    );
  }
}
