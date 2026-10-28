import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_recap.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un mois clos : quand et par qui, puis « Rouvrir le mois » pour la
/// direction (`hr.attendance.reopen`), tant que le serveur l'accepterait
/// (`reopenable` : année en cours, paie pas validée).
class HrPresenceRecapClosed extends StatelessWidget {
  final HrAttendanceRecap recap;

  /// Le dernier geste posé ici sur ce mois — une réouverture — a été
  /// refusé : le dire avant d'offrir de recommencer.
  final bool refused;
  final bool reopening;
  final VoidCallback onReopen;

  const HrPresenceRecapClosed({
    super.key,
    required this.recap,
    this.refused = false,
    required this.reopening,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final when = PresenceLabels.moment(
      MaterialLocalizations.of(context),
      recap.closedAt,
    );
    final by = recap.closedBy;
    final banner = PresenceWarning(
      icon: Icons.lock_outline,
      tone: PresenceStatus.present,
      message: [
        l10n.staffAttendanceMonthClosedBanner,
        if (when != null && by != null)
          l10n.hrPresenceRecapClosedBy(when, by)
        else
          ?when,
        l10n.staffAttendanceCloseIrreversible,
      ].join(' · '),
    );
    final canReopen =
        recap.reopenable &&
        PermissionGate.allowsAccess(context, kStaffAttendanceReopenAccess);
    if (!canReopen && !refused) return banner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (refused) ...[
          PresenceWarning(
            icon: Icons.sync_problem,
            tone: PresenceStatus.absent,
            message: l10n.hrPresenceRecapCloseRefused,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        banner,
        if (canReopen) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: EteeloButton.secondary(
              label: l10n.hrPresenceRecapReopen,
              icon: Icons.lock_open,
              isLoading: reopening,
              onPressed: reopening ? null : onReopen,
              fullWidth: false,
            ),
          ),
        ],
      ],
    );
  }
}

/// Une clôture ou une réouverture posée sur la tablette et pas encore reçue :
/// le serveur ne la voit pas encore.
class HrPresenceRecapPendingLock extends StatelessWidget {
  final StaffAttendanceLock lock;

  const HrPresenceRecapPendingLock({super.key, required this.lock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloPanelCard(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            lock.locked ? Icons.lock_clock_outlined : Icons.lock_open,
            color: AppColors.textSecondary,
          ),
          Text(
            lock.locked
                ? l10n.hrPresenceRecapClosedOnTablet
                : l10n.hrPresenceRecapReopenedOnTablet,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          RecordSyncPill(state: lock.syncState),
        ],
      ),
    );
  }
}
