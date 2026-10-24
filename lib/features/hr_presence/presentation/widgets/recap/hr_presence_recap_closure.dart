import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_card_frame.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La clôture du mois (spec §14, revue E2, E4–E6) : un verrou, rien n'est
/// transmis — la Paie relit les pointages réels. Seule la direction clôt
/// (`hr.attendance.manage`), un mois fini seulement, et sans retour.
class HrPresenceRecapClosure extends StatelessWidget {
  final HrPresenceRecapState state;
  final VoidCallback onClose;

  const HrPresenceRecapClosure({
    super.key,
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recap = state.recap!;
    final local = state.localLock;
    if (recap.closed) {
      final when = PresenceLabels.moment(
        MaterialLocalizations.of(context),
        recap.closedAt,
      );
      final by = recap.closedBy;
      return PresenceWarning(
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
    }
    if (local != null && local.locked) {
      // Posée ici, pas encore reçue : le serveur ne la voit pas encore.
      return PresenceCardFrame(
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(
              Icons.lock_clock_outlined,
              color: AppColors.textSecondary,
            ),
            Text(
              l10n.hrPresenceRecapClosedOnTablet,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            RecordSyncPill(state: local.syncState),
          ],
        ),
      );
    }
    final lastDay = SchoolDayCalendar.daysOf(recap.month).last;
    return PresenceCardFrame(
      title: recap.toDate
          ? l10n.hrPresenceRecapCurrentMonth
          : l10n.hrPresenceRecapNotClosed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recap.unscored > 0) ...[
            PresenceWarning(
              icon: Icons.back_hand_outlined,
              message: l10n.hrPresenceUnscoredTitle(recap.unscored),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (state.unsynced > 0) ...[
            PresenceWarning(
              icon: Icons.cloud_off_outlined,
              tone: PresenceStatus.none,
              message: l10n.hrPresenceUnsyncedTitle(state.unsynced),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            l10n.hrPresenceRecapCloseExplain,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          // E2 : la direction seule ; les autres ne voient pas le bouton.
          if (PermissionGate.allowsAccess(
            context,
            kStaffAttendanceManageAccess,
          )) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EteeloButton.primary(
                  label: l10n.staffAttendanceClose,
                  icon: Icons.lock,
                  isLoading: state.closing,
                  onPressed: recap.closable && !state.closing ? onClose : null,
                  fullWidth: false,
                ),
                // E5 : un mois se clôt au plus tôt son dernier jour.
                if (!recap.closable)
                  Text(
                    l10n.hrPresenceRecapCloseFrom(
                      MaterialLocalizations.of(
                        context,
                      ).formatFullDate(DateTime.parse(lastDay)),
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
