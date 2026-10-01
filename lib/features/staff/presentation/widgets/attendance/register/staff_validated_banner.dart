import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_lock.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Le rapport du jour validé : qui, quand, combien, où en est l'envoi — et
/// Rouvrir. Une réouverture refusée laisse le jour validé, pastille en échec :
/// Rouvrir la repose.
class StaffValidatedBanner extends StatelessWidget {
  final StaffAttendanceLock lock;
  final StaffDayRegister register;

  /// `null` quand le mois est clos : un jour d'un mois clos ne se rouvre pas.
  final VoidCallback? onReopen;

  const StaffValidatedBanner({
    super.key,
    required this.lock,
    required this.register,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final when = PresenceLabels.moment(
      MaterialLocalizations.of(context),
      lock.lockedAt,
    );
    final by = lock.lockedByName;
    final onReopen = this.onReopen;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.presenceMarkPresentSoft,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.presenceMarkPresentBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_outlined,
                color: AppColors.presenceMarkPresentInk,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.staffAttendanceValidatedTitle,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.presenceMarkPresentInk,
                    ),
                  ),
                  Text(
                    [
                      if (by != null && when != null)
                        l10n.presenceMarkValidatedBy(by, when)
                      else
                        ?when,
                      l10n.presenceMarkValidatedCounts(
                        register.count(PresenceStatus.present) +
                            register.count(PresenceStatus.none),
                        register.count(PresenceStatus.late),
                        register.count(PresenceStatus.absent),
                      ),
                    ].join(' · '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RecordSyncPill(state: lock.syncState),
              if (onReopen != null)
                PermissionGate.access(
                  kStaffAttendanceWriteAccess,
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: EteeloButton.secondary(
                      label: l10n.presenceMarkReopen,
                      icon: Icons.lock_open,
                      onPressed: onReopen,
                      fullWidth: false,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
