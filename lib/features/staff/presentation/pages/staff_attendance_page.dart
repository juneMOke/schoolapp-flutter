import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_agent_month_tab.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/month/staff_recap_tab.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_register_tab.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/staff_attendance_notices.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/staff_attendance_tabs.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/states/staff_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ressources humaines ▸ Pointage & présences — le registre du jour, la fiche
/// mensuelle d'un agent et le récapitulatif du mois.
///
/// Lecture 100 % locale, écriture 100 % file d'envoi : tout fonctionne hors
/// ligne dès la première ouverture ; un bandeau dit seulement que le fichier
/// du personnel n'est pas encore arrivé.
class StaffAttendancePage extends StatelessWidget {
  const StaffAttendancePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<StaffAttendanceCubit>(
    create: (_) => getIt<StaffAttendanceCubit>()..load(),
    child: const StaffAttendanceScreen(),
  );
}

class StaffAttendanceScreen extends StatelessWidget {
  const StaffAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPageBackground(
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

  Widget _body(BuildContext context, StaffAttendanceState state) {
    final cubit = context.read<StaffAttendanceCubit>();
    switch (state.load) {
      case StaffAttendanceLoad.failure:
        return StaffResultsErrorState(
          failure: state.failure,
          onRetry: cubit.load,
        );
      case StaffAttendanceLoad.loading:
        return const EteeloListSkeleton(rowCount: 8);
      case StaffAttendanceLoad.ready:
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.snapshot.hasEverSynced)
          EteeloNotice.warning(
            AppLocalizations.of(context)!.staffFileNotYetSynced,
          ),
        StaffAttendanceTabs(state: state, onSelect: cubit.setTab),
        const SizedBox(height: AppSpacing.lg),
        switch (state.tab) {
          StaffAttendanceTab.register => StaffRegisterTab(state: state),
          StaffAttendanceTab.agentMonth => StaffAgentMonthTab(state: state),
          StaffAttendanceTab.recap => StaffRecapTab(state: state),
        },
      ],
    );
  }
}
