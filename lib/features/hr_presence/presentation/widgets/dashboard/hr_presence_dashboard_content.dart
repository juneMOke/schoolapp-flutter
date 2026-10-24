import 'package:flutter/material.dart';
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
  final List<HrAttendanceStaffRow> rows;
  final String text;
  final int unsynced;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onClearText;

  /// `null` : le compte ne pointe pas.
  final VoidCallback? onCompleteMarking;
  final ValueChanged<HrAttendanceStaffRow>? onOpen;

  const HrPresenceDashboardContent({
    super.key,
    required this.dashboard,
    required this.window,
    required this.periodLabel,
    required this.rows,
    required this.text,
    required this.unsynced,
    required this.onTextChanged,
    required this.onClearText,
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
        HrPresenceStaffCard(
          dashboard: dashboard,
          window: window,
          periodLabel: periodLabel,
          rows: rows,
          text: text,
          onTextChanged: onTextChanged,
          onClearText: onClearText,
          onOpen: onOpen,
        ),
      ],
    );
  }
}
