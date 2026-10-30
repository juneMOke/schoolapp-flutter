import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_warning.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/bloc/recap/hr_presence_recap_state.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/recap/hr_presence_recap_closed.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La clôture du mois (spec §14, revue E2, E4–E6) : un verrou, rien n'est
/// transmis — la Paie lit le résumé du mois clos. Seule la direction clôt
/// (`hr.attendance.manage`), un mois fini seulement ; elle seule le rouvre
/// (`hr.attendance.reopen`), tant que sa paie n'est pas validée.
///
/// Ouvert, le mois tient en une carte : ce qui manque en une ligne, et le
/// bouton à côté.
class HrPresenceRecapClosure extends StatelessWidget {
  final HrPresenceRecapState state;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  const HrPresenceRecapClosure({
    super.key,
    required this.state,
    required this.onClose,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recap = state.recap!;
    final local = state.localLock;
    // Un geste posé ici et pas encore reçu : le serveur ne le voit pas encore.
    if (local != null && local.syncState == RecordSyncState.pending) {
      return HrPresenceRecapPendingLock(lock: local);
    }
    if (recap.closed || (local?.locked ?? false)) {
      return HrPresenceRecapClosed(
        recap: recap,
        refused: local?.syncState == RecordSyncState.failed,
        refusalCode: local?.syncErrorCode,
        reopening: state.reopening,
        onReopen: onReopen,
      );
    }
    final lastDay = SchoolDayCalendar.daysOf(recap.month).last;
    // E2 : la direction seule ; les autres ne voient pas le bouton.
    final canClose = PermissionGate.allowsAccess(
      context,
      kStaffAttendanceManageAccess,
    );
    final action = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        EteeloButton.primary(
          label: l10n.staffAttendanceClose,
          icon: Icons.lock,
          isLoading: state.closing,
          onPressed: recap.closable && !state.closing ? onClose : null,
          fullWidth: false,
        ),
        // E5 : un mois se clôt au plus tôt son dernier jour.
        if (!recap.closable && recap.toDate) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.hrPresenceRecapCloseFrom(
              MaterialLocalizations.of(
                context,
              ).formatFullDate(DateTime.parse(lastDay)),
            ),
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        ],
      ],
    );
    final summary = _Summary(
      title: recap.toDate
          ? l10n.hrPresenceRecapCurrentMonth
          : l10n.hrPresenceRecapNotClosed,
      unscored: recap.unscored,
      unsynced: state.unsynced,
    );
    return EteeloPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Une clôture posée ici que le serveur a refusée : le dire avant
          // d'offrir de recommencer.
          if (local != null && local.syncState == RecordSyncState.failed) ...[
            PresenceWarning(
              icon: Icons.sync_problem,
              tone: PresenceStatus.absent,
              message: l10n.hrPresenceRecapCloseRefused,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              // Au large, le bouton à droite de ce qu'il fige ; sur un
              // téléphone, dessous.
              if (!canClose) return summary;
              if (constraints.maxWidth < AppBreakpoints.dataTableCardsMax) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    const SizedBox(height: AppSpacing.md),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: AppSpacing.lg),
                  action,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Le mois en une ligne : ce qui manque (jours non pointés, pointages encore
/// sur la tablette), puis ce que fait la clôture.
class _Summary extends StatelessWidget {
  final String title;
  final int unscored;
  final int unsynced;

  const _Summary({
    required this.title,
    required this.unscored,
    required this.unsynced,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = AppTypography.bodySmall.copyWith(
      color: AppColors.textSecondary,
    );
    final missing = AppTypography.bodySmall.copyWith(
      color: AppColors.presenceMarkLateInk,
      fontWeight: FontWeight.w700,
    );
    final parts = [
      if (unscored > 0)
        TextSpan(text: l10n.hrPresenceUnscoredTitle(unscored), style: missing),
      if (unsynced > 0) TextSpan(text: l10n.hrPresenceUnsyncedTitle(unsynced)),
      TextSpan(text: l10n.hrPresenceRecapCloseExplain),
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          unscored > 0 ? Icons.back_hand_outlined : Icons.lock_clock_outlined,
          color: unscored > 0
              ? AppColors.presenceMarkLateInk
              : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    for (final (i, part) in parts.indexed) ...[
                      if (i > 0) const TextSpan(text: ' · '),
                      part,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
