import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/dashboard/hr_presence_dashboard_cubit.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_dashboard_notices.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_kpis.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_rate_card.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_staff_card.dart';

/// Le tableau de bord prêt, de haut en bas : les chiffres, ce qui manque
/// (non pointés, pas encore envoyés), le graphique, les agents.
class HrPresenceDashboardContent extends StatelessWidget {
  final HrAttendanceDashboard dashboard;
  final DashboardWindow window;
  final String periodLabel;
  final int unsynced;

  /// `null` : le compte ne pointe pas.
  final VoidCallback? onCompleteMarking;
  final ValueChanged<HrAttendanceStaffRow>? onOpen;

  const HrPresenceDashboardContent({
    super.key,
    required this.dashboard,
    required this.window,
    required this.periodLabel,
    required this.unsynced,
    this.onCompleteMarking,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final unscored = dashboard.kpis.unscored;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HrPresenceKpis(kpis: dashboard.kpis),
        if (unscored > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          HrPresenceUnscoredNotice(
            unscored: unscored,
            onComplete: onCompleteMarking,
          ),
        ],
        if (unsynced > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          HrPresenceUnsyncedNotice(unsynced: unsynced),
        ],
        const SizedBox(height: AppSpacing.lg),
        HrPresenceRateCard(dashboard: dashboard),
        const SizedBox(height: AppSpacing.lg),
        // Seule la liste suit la frappe : les chiffres et le graphique ne se
        // reconstruisent pas à chaque lettre.
        BlocBuilder<HrPresenceDashboardCubit, HrPresenceDashboardState>(
          buildWhen: (previous, current) =>
              previous.text != current.text ||
              previous.dashboard != current.dashboard,
          builder: (context, state) {
            final cubit = context.read<HrPresenceDashboardCubit>();
            return HrPresenceStaffCard(
              dashboard: dashboard,
              window: window,
              periodLabel: periodLabel,
              rows: state.visibleStaff,
              text: state.text,
              onTextChanged: cubit.setText,
              onClearText: cubit.clearText,
              onOpen: onOpen,
            );
          },
        ),
      ],
    );
  }
}
